from prefect import flow, task


@task
def greet():
    print("Hello from prefect!")


@task
def goodbye():
    print("Goodbye from prefect!")


@flow
def hello_world():
    greet()
    goodbye()


if __name__ == "__main__":
    hello_world.deploy(
        name="hello-world",
        work_pool_name="local-pool",
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
