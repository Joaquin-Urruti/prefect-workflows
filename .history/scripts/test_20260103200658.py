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
        work_pool_name="local-pool",
        cron="* * * * *",  # Ejecutar cada minuto
        tags=["local", "test"],
    )
