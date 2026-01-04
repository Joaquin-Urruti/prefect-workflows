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
    hello_world.serve(
        name="hello-world-workflow",
    )
