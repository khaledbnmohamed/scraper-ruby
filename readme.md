## Getting Started

### Prerequisites

- Ruby (2.7 or later)
- Docker

### Usage


#### Running the Script in Docker

1. Build the project:

```bash
docker-compose up fetcher --build
```
2. Running examples:

```bash
docker-compose run fetcher https://www.google.com https://autify.com
```

```bash
docker-compose run fetcher --metadata https://www.fast.com
```

### Additional Enhancements

1. Add more specific error handling
2. Add tests
3. Provide more options for the user to specify the output format
4. Apply the await function properly in case of batch requests

