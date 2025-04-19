# Tournament Management with Ruby and Docker

## Overview
This repository features four backend projects, all based on the same scenario: managing a badminton knock-out tournament. The projects are centered around implementing and thoroughly testing five predefined access patterns using different database technologies. Each version demonstrates how the same application logic can be realized with:

- `Redis`

- `MongoDB`

- `Neo4j`

- `DynamoDB`

The purpose of this setup is to deepen our understanding of various database models by applying them in a controlled and comparable context.

## Technology Stack
- Programming Language: `Ruby`

- Containerization: `Docker`

- Database (varies by project): - `Redis`, `MongoDB`, `Neo4j` and `DynamoDB`

Each project is structured similarly to allow direct comparison of:

- Data modeling strategies
- Query implementation
- Performance and usability for the defined use case

## Scenario: Badminton K.O. Tournament
The system simulates a badminton single-elimination tournament with the following key rules:

- Each match is played between two players.
- A game ends when one player scores 11 points.
- A match ends when one player wins 2 out of 3 possible games.

The tournament progresses round by round until a final winner is determined.

## Access Patterns
The application must support the following common access patterns, which are implemented and tested in each version:

1. Initialize Tournament
Create a new tournament and register all initial players.

2. Create Match
Set up a new match by assigning two players.

3. Register Player
Add a new player to an existing tournament.

4. Submit Game Result
Record the outcome of a specific game within a match. And update player statistics.

5. Fetch Match History
Retrieve the complete match history for a given player.

Each access pattern is clearly visible in the code and was used as the basis for evaluating database suitability.

## Redis
<details> <summary>Click to expand Redis-specific implementation details</summary>

- Type: Key-Value Store

- Modeling: Data is stored using structured keys, e.g., tournament:<id>:round:<n> or match:<id>:score.

- Strengths: Fast access, simplicity, good for caching and atomic updates.

- Challenges: No native support for complex relations, manual key structure design needed.

</details>

## MongoDB
<details> <summary>Click to expand MongoDB-specific implementation details</summary>

- Type: Document Store

- Modeling: Matches, players, and games are stored as nested documents.

- Strengths: Natural for hierarchical data, flexible schema.

- Challenges: Querying deep structures requires careful design; relations need embedding or referencing.

</details>

## Neo4j
<details> <summary>Click to expand Neo4j-specific implementation details</summary>

- Type: Graph Database

- Modeling: Players, matches, and rounds are nodes; results and participation are edges.

- Strengths: Optimal for relationship-heavy queries (e.g., player paths through the tournament).

- Challenges: Requires rethinking in terms of graph structures; Cypher query language.

</details>

## DynamoDB
<details> <summary>Click to expand DynamoDB-specific implementation details</summary>

- Type: NoSQL (Key-Value / Document hybrid)

- Modeling: Composite keys and global secondary indexes used to model tournament rounds and player histories.

- Strengths: Scalability, predictable performance, flexible schema.

- Challenges: Requires a deep understanding of access patterns upfront; limited querying flexibility without indexes.

</details>

## License

This project is licensed under [AGPL-3.0](LICENSE). 