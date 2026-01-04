from prefect import task, flow

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
    hello_world()
