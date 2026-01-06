from pyspark.sql import SparkSession
from pyspark import SparkConf

conf = SparkConf() \
    .set("spark.driver.cores", "1") \
    .set("spark.driver.memory", "512m") \
    .set("spark.executor.cores", "1") \
    .set("spark.executor.memory", "512m")

spark = SparkSession.builder \
    .appName("Creating Delta Schema") \
    .config(conf=conf) \
    .enableHiveSupport() \
    .getOrCreate()

spark.sql("""
    CREATE DATABASE IF NOT EXISTS bronze LOCATION 's3a://dutchboy.db/bronze'
""")
print("Bronze schema created")

#spark.sql("""
#    CREATE DATABASE IF NOT EXISTS silver LOCATION 's3a://dutchboy.db/silver'
#""")
# print("Silver schema created")

# spark.sql("""
#     CREATE DATABASE IF NOT EXISTS gold LOCATION 's3a://dutchboy.db/gold'
# """)
# print("Gold schema created")
