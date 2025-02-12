
# Power Flow Analysis Tool

A web-based application for performing power flow analysis. Built with Ruby and Sinatra, this tool allows users to upload CSV files containing load and line information, provides an interactive interface for building power flow schematics, and validates user inputs to ensure proper convergence.

## Features

- **CSV Upload**: Upload CSVs containing load and line info to define your power flow schematic.
- **Interactive Interface**: Build your power flow schematic directly in the browser.
- **Automatic Validation**: Ensures that all parameters and information in the CSV uploads are provided and non-null to encourage convergence.
- **Fully Web-Based**: Access the tool from any web browser.

## Installation

### Prerequisites

Ensure you have the following software installed:

- Ruby (>= 3.2.2)
- Bundler (for managing gems)

### Cloning the Repository

```bash
git clone https://github.com/devxiongmao/power-flow-analysis.git
cd power-flow-analysis
```

### Installing Dependencies

Run the following command to install the required dependencies:

```bash
bundle install
```

Alternatively, you can use the Makefile:

```bash
make install
```

### Running the Application

To start the application, use the following command:

```bash
make dev
```

The application will start locally on `http://localhost:4567`.

## Usage

- Open your web browser and go to `http://localhost:4567`.
- Upload your CSV file containing the load and line information for your power flow schematic.
- Use the interactive interface to build and modify the schematic.
- Ensure that your input data is valid and non-null for proper operation of the tool.

## Testing

This project uses rspec for testing. To run tests, simply run:

```bash
make test
```

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix (`git checkout -b feature-name`).
3. Make your changes and commit them (`git commit -am 'Add feature-name'`).
4. Push to your fork (`git push origin feature-name`).
5. Create a pull request.

Please make sure your changes pass the necessary tests and follow the project's code style.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
