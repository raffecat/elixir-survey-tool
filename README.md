# Survey Tool

An Elixir CLI (EScript) application to parse and display survey data from CSV files.

Build and run as follows:

```
mix deps.get
mix escript.build
./survey_tool example-data/survey-1.csv example-data/survey-1-responses.csv
```

Run tests and generate a coverage report:

```
mix test --cover
```

Generate the documentation:

```
mix docs
```

## Implementation Notes

The implementation is split into five main modules, each responsible for one
aspect of the tool.

### cli.ex

* Contains the EScript entry point
* Validates command-line arguments
* Handles output on behalf of the tool

This module uses the `Parse`, `Summary` and `Report` modules to perform
three phases of work: parse input files, compute summary information
from responses, and generate a report.

All output (stdout/stderr) is performed from this module so the remainder of
the code can be cleanly tested. This also allows the other modules to be used
in a non-command-line context.

### parse.ex

* Uses `NimbleCSV` to parse CSV files.
* Validates the survey file and creates `Question` structs.
* Generates a lazy `Stream` of response rows.
* Provides friendly CLI error messages.

This module parses questions from the survey file using NimbleCSV and ensures
that all required columns are present.

NimbleCSV doesn't handle CSV headers, so this module captures the first row
and uses it to generate a map for each subsequent row. It then pattern-matches
those maps to extract the required `Question` fields.

The field values are permitted to contain any text at this stage; question
types are matched in the `Summary` module while processing response rows.

Response rows are parsed lazily via the `Stream` interface to avoid bringing
them all into memory at once. This allows the utility to handle large response
files within O(1) rather than O(n) memory.

Validation of response rows is left to the `Summary` module (i.e. missing
columns, numeric fields.) They are presented here as a stream of lists.

Although Elixir code tends to follow a _let it crash_ discipline, this module
errs on the side of providing helpful error messages for the CLI tool.

One of the error paths for question parsing uses a `throw` to surface an error
message. I'm not sure that this is considered clean or idiomatic, but matching
on `{:error}` within `Enum.map` proved clumsy (it's in the commit labelled
"Cleaned up error handling and CLI module".)

### summary.ex

* Counts submitted response rows and total number of rows.
* Matches answer columns against question types.
* Accumulates an aggregate value for each question.

This module implements a single-pass algorithm over the `Stream` of response
rows to accumulate summary information.

It begins by generating an initial aggregate value (a struct) for each question
based on its type. At this time, only `ratingquestion` actually accumulates an
aggregate, but this can be easily extended.

It then reduces over the stream of rows, accumulating a `Stats` struct as it
processes each row. The `Stats` struct includes the current aggregate values.

For each submitted row, it maps over the answer columns in that row paired
with current aggregate values to produce new aggregate values. Pattern
matching on the aggregate struct-type is used to determine how to parse
and accumulate each answer.

In the case of `ratingquestion`, its `Rating` struct is used to accumulate
the total number of times the question was answered and the sum of all
answers (integers in the range `1..5`.) These are used to compute the average
rating during report generation.

Like in the `Parse` module, several parsing errors are handled in this module
using a `throw` caught at the module entry point. Again, this approach keeps
the rest of the map/reduce code cleaner than it would be if they had to stop
on errors and use the `{:ok / :error}` pattern.

### report.ex

* Generates a report in the form of a `String.t`
* Consumes the `Stats` struct from the `Summary` module.

This module formats the accumulated stats for display and generates a
textual report for command-line output. It returns a string, rather than
performing IO directly, to simplify testing and because it allows the
output to be directed elsewhere, e.g. a file, network, or process.

Survey `Question` structs are paired with their accumulated aggregate value
and formatted for display based on the `type` of the Question, supporting
extensibility.

### models.ex

* Contains structs used in the other modules.

The structs in this module represent data with known shape that is passed
between the other modules. These are used in pattern matching and contain
some model-specific helper functions.

They also improve error detection (over bare maps) and make the code easier
to read and maintain.
