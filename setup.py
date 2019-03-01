import setuptools

with open("README.md", "rb") as fin:
    long_description = fin.read().decode("utf-8")

setuptools.setup(
    name="rememberme",
    version="0.1.0",
    packages=setuptools.find_packages(),
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/liwt31/remember-me",
    install_requires=["print-tree2"],
    license="MIT",
    author="Weitang Li",
    author_email="liwt31@163.com",
    description="Rememberme is a handy tool for memory problems in Python.",
)
