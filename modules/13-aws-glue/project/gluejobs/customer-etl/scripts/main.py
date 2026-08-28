import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

REQUIRED_ARGS = ["JOB_NAME", "env", "source_bucket", "target_bucket", "database"]

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)

args = getResolvedOptions(sys.argv, REQUIRED_ARGS)
job.init(args["JOB_NAME"], args)

print(f"Running customer-etl in {args['env']}")
print(f"Source: {args['source_bucket']} -> Target: {args['target_bucket']}")

job.commit()
