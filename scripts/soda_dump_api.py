#!/usr/bin/env python3
"""
Soda Cloud API Data Dump Script
This script extracts dataset and check information from Soda Cloud API
and stores the data locally as CSV files for analysis and reporting.
"""

import os
import sys
import time
import requests
import pandas as pd
from datetime import datetime
from dotenv import load_dotenv
import logging
import glob

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SodaCloudDump:
    def __init__(self):
        """Initialize the Soda Cloud API dump utility."""
        # Soda Cloud configuration
        cloud_host = os.getenv('SODA_CLOUD_HOST', 'https://cloud.us.soda.io')
        # Ensure URL has proper scheme
        if not cloud_host.startswith('http'):
            cloud_host = f'https://{cloud_host}'
        self.soda_cloud_url = cloud_host
        self.soda_apikey = os.getenv('SODA_CLOUD_API_KEY_ID')
        self.soda_apikey_secret = os.getenv('SODA_CLOUD_API_KEY_SECRET')
        
        # Output directory for CSV files
        self.output_dir = 'soda_dump_output'
        
        # Initialize data containers
        self.datasets = []
        self.checks = []
        
        # Validate configuration
        self._validate_config()
        
    def _validate_config(self):
        """Validate that required configuration is present."""
        if not self.soda_apikey or not self.soda_apikey_secret:
            logger.error("Soda Cloud API credentials not found in environment variables.")
            logger.error("Please set SODA_CLOUD_API_KEY_ID and SODA_CLOUD_API_KEY_SECRET")
            sys.exit(1)
            
        logger.info(f"Using Soda Cloud URL: {self.soda_cloud_url}")
        logger.info("Soda Cloud API credentials found")
        
    def _create_output_directory(self):
        """Create output directory if it doesn't exist."""
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
            logger.info(f"Created output directory: {self.output_dir}")
        else:
            logger.info(f"Using existing output directory: {self.output_dir}")
            
    def _make_api_request(self, url, description):
        """Make API request with error handling and rate limiting."""
        try:
            response = requests.get(
                url,
                auth=(self.soda_apikey, self.soda_apikey_secret),
                timeout=30
            )
            
            if response.status_code == 200:
                return response
            elif response.status_code == 401:
                logger.error("Unauthorized access. Please check your API keys.")
                sys.exit(1)
            elif response.status_code == 403:
                logger.error("Forbidden access. Please check your permissions in Soda Cloud.")
                sys.exit(1)
            elif response.status_code == 429:
                logger.warning("API Rate Limit reached. Pausing for 5 seconds...")
                time.sleep(5)
                return self._make_api_request(url, description)  # Retry
            else:
                logger.error(f"Error {description}. Status code: {response.status_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed for {description}: {e}")
            return None
            
    def fetch_datasets(self):
        """Fetch ALL dataset information from Soda Cloud."""
        logger.info("Fetching ALL dataset information from Soda Cloud...")
        
        # Fetch all datasets without filtering
        logger.info("Fetching all datasets from Soda Cloud...")
        
        # Initial request to get total pages
        initial_url = f"{self.soda_cloud_url}/api/v1/datasets?page=0"
        response = self._make_api_request(initial_url, "initial datasets")
        
        if not response:
            logger.error("Failed to fetch initial datasets")
            return False
            
        try:
            total_pages = response.json().get('totalPages', 0)
            logger.info(f"Found {total_pages} pages of datasets")
            
            # Fetch all pages
            for page in range(total_pages):
                url = f"{self.soda_cloud_url}/api/v1/datasets?page={page}"
                response = self._make_api_request(url, f"datasets page {page}")
                
                if response:
                    datasets_page = response.json().get('content', [])
                    self.datasets.extend(datasets_page)
                    logger.info(f"Fetched {len(datasets_page)} datasets from page {page}")
                    
                    # Small delay to be respectful to the API
                    time.sleep(0.5)
                else:
                    logger.error(f"Failed to fetch datasets from page {page}")
                    
        except Exception as e:
            logger.error(f"Error processing datasets: {e}")
            return False
                
        logger.info(f"Total datasets fetched: {len(self.datasets)}")
        return True
        
    def fetch_checks(self):
        """Fetch ALL check information from Soda Cloud."""
        logger.info("Fetching ALL check information from Soda Cloud...")
        
        # Fetch all checks without filtering
        logger.info("Fetching all checks from Soda Cloud...")
        
        # Initial request to get total pages
        initial_url = f"{self.soda_cloud_url}/api/v1/checks?size=100&page=0"
        response = self._make_api_request(initial_url, "initial checks")
        
        if not response:
            logger.error("Failed to fetch initial checks")
            return False
            
        try:
            total_pages = response.json().get('totalPages', 0)
            logger.info(f"Found {total_pages} pages of checks")
            
            # Fetch all pages
            for page in range(total_pages):
                url = f"{self.soda_cloud_url}/api/v1/checks?size=100&page={page}"
                response = self._make_api_request(url, f"checks page {page}")
                
                if response:
                    checks_page = response.json().get('content', [])
                    self.checks.extend(checks_page)
                    logger.info(f"Fetched {len(checks_page)} checks from page {page}")
                    
                    # Small delay to be respectful to the API
                    time.sleep(0.5)
                else:
                    logger.error(f"Failed to fetch checks from page {page}")
                    
        except Exception as e:
            logger.error(f"Error processing checks: {e}")
            return False
                
        logger.info(f"Total checks fetched: {len(self.checks)}")
        return True
    
    @staticmethod
    def find_latest_file(pattern, output_dir='soda_dump_output'):
        """Find the latest file matching a pattern in the output directory."""
        if not os.path.exists(output_dir):
            return None
            
        files = glob.glob(os.path.join(output_dir, pattern))
        if not files:
            return None
        
        # Try to sort by timestamp in filename first, then by modification time
        def get_timestamp_from_filename(filepath):
            """Extract timestamp from filename for sorting."""
            filename = os.path.basename(filepath)
            # Look for pattern like YYYYMMDD_HHMMSS
            import re
            match = re.search(r'(\d{8}_\d{6})', filename)
            if match:
                return match.group(1)
            return None
        
        # Sort by timestamp in filename if available, otherwise by modification time
        def sort_key(filepath):
            timestamp = get_timestamp_from_filename(filepath)
            if timestamp:
                return timestamp
            else:
                # Use modification time as fallback
                return os.path.getmtime(filepath)
        
        try:
            # Sort by timestamp (newest first)
            files.sort(key=sort_key, reverse=True)
            return files[0]
        except:
            # Fallback to modification time
            latest_file = max(files, key=os.path.getmtime)
            return latest_file
    
    @staticmethod
    def get_latest_datasets_file(output_dir='soda_dump_output'):
        """Get the path to the latest datasets CSV file."""
        logger = logging.getLogger(__name__)
        
        # First try the _latest.csv file
        latest_file = os.path.join(output_dir, 'datasets_latest.csv')
        if os.path.exists(latest_file):
            logger.info(f"Found _latest.csv file: {latest_file}")
            return latest_file
            
        # If not found, find the most recent timestamped file
        timestamped_file = SodaCloudDump.find_latest_file('datasets_*.csv', output_dir)
        if timestamped_file:
            logger.info(f"Found latest timestamped datasets file: {timestamped_file}")
            return timestamped_file
        
        logger.warning(f"No datasets files found in {output_dir}")
        return None
    
    @staticmethod
    def get_latest_checks_file(output_dir='soda_dump_output'):
        """Get the path to the latest checks CSV file."""
        logger = logging.getLogger(__name__)
        
        # First try the _latest.csv file
        latest_file = os.path.join(output_dir, 'checks_latest.csv')
        if os.path.exists(latest_file):
            logger.info(f"Found _latest.csv file: {latest_file}")
            return latest_file
            
        # If not found, find the most recent timestamped file
        timestamped_file = SodaCloudDump.find_latest_file('checks_*.csv', output_dir)
        if timestamped_file:
            logger.info(f"Found latest timestamped checks file: {timestamped_file}")
            return timestamped_file
        
        logger.warning(f"No checks files found in {output_dir}")
        return None
        
    def save_to_csv(self):
        """Save datasets and checks data to CSV files with enhanced timestamping."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        date_str = datetime.now().strftime("%Y-%m-%d")
        
        logger.info(f"Saving all data with timestamp: {timestamp}")
        
        # Save datasets
        if self.datasets:
            df_datasets = pd.DataFrame(self.datasets)
            
            # Create timestamped file with better naming
            datasets_file = f"{self.output_dir}/datasets_{timestamp}.csv"
            df_datasets.to_csv(datasets_file, index=False)
            logger.info(f"✅ Saved {len(self.datasets)} datasets to {datasets_file}")
            
            # Also save latest version without timestamp (for easy access)
            latest_datasets_file = f"{self.output_dir}/datasets_latest.csv"
            df_datasets.to_csv(latest_datasets_file, index=False)
            logger.info(f"✅ Saved latest datasets to {latest_datasets_file}")
            
            # Create a date-based file for daily tracking
            daily_datasets_file = f"{self.output_dir}/datasets_{date_str}.csv"
            df_datasets.to_csv(daily_datasets_file, index=False)
            logger.info(f"✅ Saved daily datasets to {daily_datasets_file}")
            
            # Display sample data
            logger.info("📊 Sample datasets data:")
            logger.info(f"   Columns: {list(df_datasets.columns)}")
            if not df_datasets.empty:
                logger.info(f"   First dataset: {df_datasets.iloc[0].to_dict()}")
        else:
            logger.warning("⚠️ No datasets data to save")
            
        # Save checks
        if self.checks:
            df_checks = pd.DataFrame(self.checks)
            
            # Create timestamped file with better naming
            checks_file = f"{self.output_dir}/checks_{timestamp}.csv"
            df_checks.to_csv(checks_file, index=False)
            logger.info(f"✅ Saved {len(self.checks)} checks to {checks_file}")
            
            # Also save latest version without timestamp (for easy access)
            latest_checks_file = f"{self.output_dir}/checks_latest.csv"
            df_checks.to_csv(latest_checks_file, index=False)
            logger.info(f"✅ Saved latest checks to {latest_checks_file}")
            
            # Create a date-based file for daily tracking
            daily_checks_file = f"{self.output_dir}/checks_{date_str}.csv"
            df_checks.to_csv(daily_checks_file, index=False)
            logger.info(f"✅ Saved daily checks to {daily_checks_file}")
            
            # Display sample data
            logger.info("🔍 Sample checks data:")
            logger.info(f"   Columns: {list(df_checks.columns)}")
            if not df_checks.empty:
                logger.info(f"   First check: {df_checks.iloc[0].to_dict()}")
        else:
            logger.warning("⚠️ No checks data to save")
            
    def generate_summary_report(self):
        """Generate a summary report of the extracted data."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = f"{self.output_dir}/summary_report_{timestamp}.txt"
        
        with open(report_file, 'w') as f:
            f.write("Soda Cloud API Data Dump Summary Report\n")
            f.write("Soda Certification Project - Specific Data Sources\n")
            f.write("=" * 60 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Soda Cloud URL: {self.soda_cloud_url}\n")
            f.write("Data Sources: soda_certification_raw, soda_certification_staging, soda_certification_mart, soda_certification_quality\n\n")
            
            f.write("DATASETS SUMMARY:\n")
            f.write("-" * 20 + "\n")
            f.write(f"Total datasets: {len(self.datasets)}\n")
            
            if self.datasets:
                df_datasets = pd.DataFrame(self.datasets)
                f.write(f"Dataset columns: {', '.join(df_datasets.columns)}\n")
                
                # Health status summary
                if 'health' in df_datasets.columns:
                    health_counts = df_datasets['health'].value_counts()
                    f.write(f"Health status distribution:\n")
                    for status, count in health_counts.items():
                        f.write(f"  {status}: {count}\n")
                        
            f.write("\nCHECKS SUMMARY:\n")
            f.write("-" * 20 + "\n")
            f.write(f"Total checks: {len(self.checks)}\n")
            
            if self.checks:
                df_checks = pd.DataFrame(self.checks)
                f.write(f"Check columns: {', '.join(df_checks.columns)}\n")
                
                # Check result summary
                if 'result' in df_checks.columns:
                    result_counts = df_checks['result'].value_counts()
                    f.write(f"Check result distribution:\n")
                    for result, count in result_counts.items():
                        f.write(f"  {result}: {count}\n")
                        
        logger.info(f"Summary report saved to {report_file}")
        
    def run(self):
        """Run the complete Soda Cloud data dump process."""
        logger.info("Starting Soda Cloud API data dump...")
        
        # Create output directory
        self._create_output_directory()
        
        # Fetch datasets
        if not self.fetch_datasets():
            logger.error("Failed to fetch datasets")
            return False
            
        # Fetch checks
        if not self.fetch_checks():
            logger.error("Failed to fetch checks")
            return False
            
        # Save to CSV
        self.save_to_csv()
        
        # Generate summary report
        self.generate_summary_report()
        
        logger.info("Soda Cloud API data dump completed successfully!")
        logger.info(f"Output files saved in: {self.output_dir}/")
        
        return True

def main():
    """Main function to run the Soda Cloud dump."""
    print("Soda Cloud API Data Dump")
    print("=" * 30)
    
    # Check if required environment variables are set
    required_vars = ['SODA_CLOUD_API_KEY_ID', 'SODA_CLOUD_API_KEY_SECRET']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        print("Please set these variables in your .env file or environment")
        return 1
        
    try:
        dump = SodaCloudDump()
        success = dump.run()
        
        if success:
            print("\n✅ Data dump completed successfully!")
            print(f"📁 Check the '{dump.output_dir}' directory for output files")
            
            # Print file locations for easy access
            datasets_file = SodaCloudDump.get_latest_datasets_file()
            checks_file = SodaCloudDump.get_latest_checks_file()
            
            if datasets_file:
                print(f"📊 Latest datasets file: {datasets_file}")
            if checks_file:
                print(f"🔍 Latest checks file: {checks_file}")
                
            return 0
        else:
            print("\n❌ Data dump failed!")
            return 1
            
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
