import os
import random
import time

def main():

    random.seed(time.time())

    output_dir = "output"
    output_alt_dir = "output_alt"

    # Create directories if they don't exist
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(output_alt_dir, exist_ok=True)

    # Define dataset sizes and file count
    dataset_sizes = [10, 50, 100, 500, 1000, 2000, 3000, 5000, 8000, 10000, 20000, 50000]

    for values_per_file in dataset_sizes:
        all_values = []
        filename = os.path.join(output_dir, f"{values_per_file}_file.txt")
        with open(filename, "w") as file:
            for _ in range(values_per_file):
                value = random.randint(-2147483648, 2147483647)  # Random i32 value
                all_values.append(value)
                file.write(f"{value}\n")

        random.shuffle(all_values)
        index = 0

        alt_filename = os.path.join(output_alt_dir, f"{values_per_file}_file.txt")
        with open(alt_filename, "w") as alt_file:
            for _ in range(values_per_file):
                alt_file.write(f"{all_values[index]}\n")
                index += 1
if __name__ == "__main__":
    main()