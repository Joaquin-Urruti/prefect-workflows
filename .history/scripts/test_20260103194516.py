import time

from prefect import flow, task
from prefect.logging.loggers import print_as_log


@task
def greet():
    print_as_log("Hello from prefect!")
    time.sleep(20)


@task
def goodbye():
    print_as_log("Goodbye from prefect!")
    time.sleep(20)


@flow
def hello_world():
    greet()
    goodbye()


if __name__ == "__main__":
    hello_world.deploy(
        name="hello-world",
        work_pool_name="docker-pool",
        work_pool_create_if_not_found=True,
        # cron="*/5 * * * * *",  # Opcional: programar ejecución cada 5 segundos (requiere soporte para cron de 6 campos)
        work_pool_type="process",
        work_pool_description="Local process pool",
        work_pool_labels={
            "env": "local",
            "owner": "prefect",
        },
        work_pool_tags=[
            "local",
            "test",
        ],
    )
