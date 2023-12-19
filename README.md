# benchmark-kinesis-connector

This project was used to demonstrate throughput capabilities in the Confluent Managed Source Connector for AWS Kinesis.

It uses the [Locust framework](https://locust.io/) to ramp traffic to Kinesis.

```mermaid
flowchart LR
subgraph EC2
    A[Locust Controller] -->|orchestrates| B(Locust Worker)
    A[Locust Controller] -->|orchestrates| C(Locust Worker)
    A[Locust Controller] -->|orchestrates| D(Locust Worker)
    A[Locust Controller] -->|orchestrates| E(Locust Worker)
end
subgraph Kinesis
    B(Locust Worker) --> K(Kinesis Data Stream)
    C(Locust Worker) --> K(Kinesis Data Stream)
    D(Locust Worker) --> K(Kinesis Data Stream)
    E(Locust Worker) --> K(Kinesis Data Stream)
end
subgraph Confluent Cloud
    K[Kinesis Data Stream] --> KC[Managed Kinesis Source Connector]

    KC[Managed Kinesis Source Connector] --> CT[Confluent Topic]
end
```

## Requirements

* [Locust Framework](https://locust.io/)
* [Terraform](https://terraform.io)
* [Confluent Cloud](https://confluent.cloud)