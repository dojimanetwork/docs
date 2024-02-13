## Running locally

### Prerequisites

Before running the site locally, you need to have the following installed:

1. [Python 3](https://www.python.org/downloads/).
2. [`virtualenv`](https://pypi.org/project/virtualenv/): Install using `pip3 install virtualenv`.

### Setup

1. **Clone repository**: Clone the Polygon Knowledge Layer repository to your local machine.
2. **Create a virtual environment**: Run `virtualenv venv; source venv/bin/activate` in the root directory.
3. **Install dependencies**: Install required Python packages with `pip3 install -r requirements.txt`.

### Running the website

Before running the website, you'll need to first load the Python virtual environment in your current shell. To do this, type the following (depending on your shell):

- **Bash**, **zsh** (most common): `virtualenv venv; source venv/bin/activate`
- **Fish**: `virtualenv venv; source venv/bin/activate.fish`
- **Nu**: `virtualenv venv; source venv/bin/activate.nu`

You only need to do the above once per shell session. Then, pick one of the following:

1. **MkDocs in strict mode**: Use `mkdocs serve --strict` for a production-like environment.
2. **MkDocs in normal mode**: Use `mkdocs serve` for a less strict, more forgiving environment, suitable for debugging.

### Docker alternative

If you prefer Docker, you can build and run the site using the following commands:

```sh
docker build -t dojima-docs .
docker compose up
```


