#!/usr/bin/env python3
"""
Focused Soda Checks Testing Script for Raw Layer Only
Tests Soda data quality checks specifically for the raw layer
"""

import os
import sys
import logging
import subprocess
import yaml
import json
from datetime import datetime
from dotenv import load_dotenv
from pathlib import Path
import time

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('soda_raw_test.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class RawLayerSodaChecker:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent.parent
        self.soda_dir = self.project_root / "soda"
        self.config_file = self.soda_dir / "configuration" / "configuration_raw.yml"
        self.checks_dir = self.soda_dir / "checks" / "raw"
        self.test_results = {}
        
    def check_soda_installation(self):
        """Check if Soda is installed and accessible"""
        logger.info("Checking Soda installation...")
        
        try:
            result = subprocess.run(
                ["soda", "--version"], 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            
            if result.returncode == 0:
                version = result.stdout.strip()
                logger.info(f"✅ Soda is installed: {version}")
                return True
            else:
                logger.error(f"❌ Soda command failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("❌ Soda command timed out")
            return False
        except FileNotFoundError:
            logger.error("❌ Soda is not installed or not in PATH")
            logger.info("Install Soda with: pip install soda-core-snowflake")
            return False
        except Exception as e:
            logger.error(f"❌ Error checking Soda installation: {e}")
            return False
    
    def get_raw_check_files(self):
        """Get all raw layer Soda check files"""
        check_files = []
        
        if self.checks_dir.exists():
            for check_file in self.checks_dir.glob("*.yml"):
                check_files.append(check_file)
        
        logger.info(f"Found {len(check_files)} raw layer check files:")
        for check_file in check_files:
            logger.info(f"  - {check_file.name}")
        
        return check_files
    
    def validate_configuration(self):
        """Validate the raw layer Soda configuration file"""
        logger.info(f"Validating configuration: {self.config_file.name}")
        
        try:
            with open(self.config_file, 'r') as f:
                config = yaml.safe_load(f)
            
            # Check for data_source keys
            data_source_keys = [key for key in config.keys() if key.startswith('data_source')]
            if not data_source_keys:
                logger.error(f"  ❌ No data_source keys found")
                return False
            
            # Check data source configuration
            data_sources = {key: config[key] for key in data_source_keys}
            if not data_sources:
                logger.error("  ❌ No data sources configured")
                return False
            
            for ds_name, ds_config in data_sources.items():
                logger.info(f"  Data source: {ds_name}")
                logger.info(f"    Type: {ds_config.get('type', 'NOT_SPECIFIED')}")
                
                # Check connection parameters
                connection = ds_config.get('connection', {})
                required_conn_params = ['account', 'username', 'password', 'database', 'schema']
                missing_params = [param for param in required_conn_params if param not in connection]
                
                if missing_params:
                    logger.warning(f"    ⚠️  Missing connection parameters: {missing_params}")
                else:
                    logger.info("    ✅ All required connection parameters present")
            
            logger.info(f"  ✅ Configuration valid: {self.config_file.name}")
            return True
            
        except yaml.YAMLError as e:
            logger.error(f"  ❌ YAML parsing error: {e}")
            return False
        except Exception as e:
            logger.error(f"  ❌ Configuration validation error: {e}")
            return False
    
    def validate_check_files(self, check_files):
        """Validate Soda check files"""
        logger.info("Validating raw layer check files...")
        
        valid_checks = []
        
        for check_file in check_files:
            logger.info(f"Validating checks: {check_file.name}")
            
            try:
                with open(check_file, 'r') as f:
                    checks = yaml.safe_load(f)
                
                # Check for required structure
                if not isinstance(checks, dict):
                    logger.error(f"  ❌ Invalid check file structure")
                    continue
                
                # Count checks
                total_checks = 0
                for table_name, table_checks in checks.items():
                    if isinstance(table_checks, list):
                        total_checks += len(table_checks)
                
                logger.info(f"  ✅ Found {total_checks} checks for {len(checks)} tables")
                valid_checks.append(check_file)
                
            except yaml.YAMLError as e:
                logger.error(f"  ❌ YAML parsing error: {e}")
            except Exception as e:
                logger.error(f"  ❌ Check validation error: {e}")
        
        return valid_checks
    
    def test_connection(self):
        """Test connection using Soda"""
        logger.info(f"Testing connection with: {self.config_file.name}")
        
        try:
            # Extract data source name from config file
            with open(self.config_file, 'r') as f:
                config = yaml.safe_load(f)
            
            data_source_keys = [key for key in config.keys() if key.startswith('data_source')]
            if not data_source_keys:
                logger.error("  ❌ No data sources found in configuration")
                return False
            
            # Get the first data source name
            data_source_key = data_source_keys[0]
            data_source_name = data_source_key.replace('data_source ', '')
            logger.info(f"  Testing data source: {data_source_name}")
            
            # Run soda test-connection command with correct syntax
            result = subprocess.run(
                ["soda", "test-connection", "-d", data_source_name, "-c", str(self.config_file)],
                capture_output=True,
                text=True,
                timeout=60,
                cwd=self.project_root
            )
            
            if result.returncode == 0:
                logger.info(f"  ✅ Connection test successful")
                return True
            else:
                logger.error(f"  ❌ Connection test failed:")
                logger.error(f"    STDOUT: {result.stdout}")
                logger.error(f"    STDERR: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error(f"  ❌ Connection test timed out")
            return False
        except Exception as e:
            logger.error(f"  ❌ Connection test error: {e}")
            return False
    
    def run_checks(self, check_files):
        """Run Soda checks for raw layer"""
        logger.info(f"Running raw layer checks with: {self.config_file.name}")
        
        # Extract data source name from config file
        with open(self.config_file, 'r') as f:
            config = yaml.safe_load(f)
        
        data_source_keys = [key for key in config.keys() if key.startswith('data_source')]
        if not data_source_keys:
            logger.error("  ❌ No data sources found in configuration")
            return {}
        
        # Get the first data source name
        data_source_key = data_source_keys[0]
        data_source_name = data_source_key.replace('data_source ', '')
        logger.info(f"  Using data source: {data_source_name}")
        
        results = {}
        
        for check_file in check_files:
            logger.info(f"  Running checks from: {check_file.name}")
            
            try:
                start_time = time.time()
                
                # Run soda scan command with correct syntax
                result = subprocess.run(
                    ["soda", "scan", "-d", data_source_name, "-c", str(self.config_file), str(check_file)],
                    capture_output=True,
                    text=True,
                    timeout=300,  # 5 minutes timeout
                    cwd=self.project_root
                )
                
                end_time = time.time()
                duration = end_time - start_time
                
                # Parse results
                check_result = {
                    'returncode': result.returncode,
                    'stdout': result.stdout,
                    'stderr': result.stderr,
                    'duration': duration,
                    'success': result.returncode == 0
                }
                
                results[check_file.name] = check_result
                
                if result.returncode == 0:
                    logger.info(f"    ✅ Checks completed successfully ({duration:.2f}s)")
                    
                    # Parse and display check results
                    self._parse_check_results(result.stdout)
                else:
                    logger.error(f"    ❌ Checks failed ({duration:.2f}s)")
                    logger.error(f"    STDOUT: {result.stdout}")
                    logger.error(f"    STDERR: {result.stderr}")
                
            except subprocess.TimeoutExpired:
                logger.error(f"    ❌ Checks timed out")
                results[check_file.name] = {
                    'returncode': -1,
                    'stdout': '',
                    'stderr': 'Timeout',
                    'duration': 300,
                    'success': False
                }
            except Exception as e:
                logger.error(f"    ❌ Check execution error: {e}")
                results[check_file.name] = {
                    'returncode': -1,
                    'stdout': '',
                    'stderr': str(e),
                    'duration': 0,
                    'success': False
                }
        
        return results
    
    def _parse_check_results(self, stdout):
        """Parse and display check results"""
        lines = stdout.split('\n')
        
        # Look for check results
        for line in lines:
            if 'check' in line.lower() and ('pass' in line.lower() or 'fail' in line.lower()):
                if 'pass' in line.lower():
                    logger.info(f"      ✅ {line.strip()}")
                else:
                    logger.warning(f"      ⚠️  {line.strip()}")
    
    def run_raw_tests(self):
        """Run all raw layer Soda tests"""
        logger.info("=" * 60)
        logger.info("SODA RAW LAYER CHECKS TESTING")
        logger.info("=" * 60)
        
        # Check Soda installation
        if not self.check_soda_installation():
            return False
        
        logger.info("")
        
        # Get raw layer check files
        check_files = self.get_raw_check_files()
        
        if not check_files:
            logger.error("No raw layer check files found!")
            return False
        
        logger.info("")
        
        # Validate configuration
        if not self.validate_configuration():
            logger.error("Configuration validation failed!")
            return False
        
        logger.info("")
        
        # Validate check files
        valid_checks = self.validate_check_files(check_files)
        if not valid_checks:
            logger.error("No valid check files found!")
            return False
        
        logger.info("")
        
        # Test connection
        if not self.test_connection():
            logger.error("Connection test failed")
            return False
        
        logger.info("")
        
        # Run checks
        results = self.run_checks(valid_checks)
        self.test_results = results
        
        # Check if any checks failed
        all_successful = True
        for check_file, result in results.items():
            if not result['success']:
                all_successful = False
        
        return all_successful
    
    def generate_report(self):
        """Generate a comprehensive test report"""
        logger.info("=" * 60)
        logger.info("SODA RAW LAYER CHECKS TEST REPORT")
        logger.info("=" * 60)
        
        total_checks = len(self.test_results)
        successful_checks = 0
        
        for check_file, result in self.test_results.items():
            if result['success']:
                successful_checks += 1
                logger.info(f"  ✅ {check_file}: PASSED ({result['duration']:.2f}s)")
            else:
                logger.error(f"  ❌ {check_file}: FAILED ({result['duration']:.2f}s)")
                if result['stderr']:
                    logger.error(f"    Error: {result['stderr']}")
        
        # Summary
        logger.info("")
        logger.info("SUMMARY:")
        logger.info(f"Total check files tested: {total_checks}")
        logger.info(f"Successful check files: {successful_checks}")
        
        if successful_checks == total_checks:
            logger.info("✅ All raw layer Soda checks are working properly!")
            logger.info("✅ Ready to proceed with data quality monitoring")
        else:
            logger.warning("⚠️  Some checks failed. Please review:")
            logger.warning("   - Check file syntax and logic")
            logger.warning("   - Data source configurations")
            logger.warning("   - Snowflake permissions and data access")
            logger.warning("   - Network connectivity and timeouts")
        
        logger.info("")
        logger.info("Next steps:")
        logger.info("1. Fix any failed checks")
        logger.info("2. Integrate Soda checks into Airflow DAG")
        logger.info("3. Set up automated monitoring and alerting")
        logger.info("4. Configure Soda Cloud for centralized monitoring")

def main():
    """Main function"""
    print("Soda Raw Layer Checks Testing for Soda Certification")
    print("=" * 60)
    
    # Check environment variables
    required_vars = ['SNOWFLAKE_ACCOUNT', 'SNOWFLAKE_USER', 'SNOWFLAKE_PASSWORD']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        print("Please create a .env file with your Snowflake credentials")
        return 1
    
    try:
        checker = RawLayerSodaChecker()
        
        # Run all tests
        success = checker.run_raw_tests()
        
        # Generate report
        checker.generate_report()
        
        return 0 if success else 1
        
    except Exception as e:
        logger.error(f"Soda testing failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
