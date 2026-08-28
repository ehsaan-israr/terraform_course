import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

REQUIRED_ARGS = ["JOB_NAME", "catalog_database", "write_mode"]

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)

args = getResolvedOptions(sys.argv, REQUIRED_ARGS)
job.init(args["JOB_NAME"], args)

print(f"Writing to {args['catalog_database']} with mode {args['write_mode']}")

job.commit()
