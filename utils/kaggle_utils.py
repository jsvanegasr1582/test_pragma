# Install dependencies as needed:
# pip install kagglehub[pandas-datasets]
import kagglehub
from kagglehub import KaggleDatasetAdapter

# Set the path to the file you'd like to load
file_path = "USvideos.csv"
#file_path = "US_category_id.json"
# Load the latest version
def import_data(file_path):
  df = kagglehub.load_dataset(
    KaggleDatasetAdapter.PANDAS,
    "datasnaek/youtube-new",
    file_path,
    # Provide any additional arguments like 
    # sql_query or pandas_kwargs. See the 
    # documenation for more information:
    # https://github.com/Kaggle/kagglehub/blob/main/README.md#kaggledatasetadapterpandas
  )
  return df