## Running the code

After installing [Zig](https://ziglang.org/learn/getting-started/), create an empty `metrics` folder. Then, run the following commands:

```sh
zig build-exe src/benchmark.zig  
./benchmark.sh        
```

This code should build the benchmarking program and run it, populating the metrics folder with different CSV files. If you want to change the execution of this program, you can change it inside `config.zig`:

```c

pub const skipListLevel: usize = 17; // changes the maxLevel for the SkipList
pub const print_steps: bool = false; // if true, prints all steps for each operation
pub const seed: u64 = 0;             // fixes seed for random events
```

Lastly, to build and run the interactive, visual application, go over to the `src` folder and run:

```sh
zig build run
```

If you change the config file, the changes will also reflect on the visualization tool, and the steps will be printed out to yor terminal.

## Running other datasets

To run with one of your datasets, simply paste it inside the `data/output` folder following the same pattern as the others. Every time you run the `benchmark.sh` script, clear the metric folder.

