import os

def write_previous_cell_to_file(cell_code: str, file_path: str):
    """
    Writes the code from the previous cell to a .py file in the utilities directory."""
    file_name = file_path.split("/")[-1]
    target_dir = "/".join(file_path.split("/")[:-1])

    os.makedirs(target_dir, exist_ok=True)

    if not cell_code.startswith(f"# {file_name}"):
        raise ValueError(f"""
        Error: The previous cell does not contain the expected GMMClusterer and ClusterFeatureAdder class definitions.
        Please ensure that the cell above has the correct code and starts with the comment '# {file_name}',
        and is executed right before this cell.
        """)
    else:
        with open(f"{target_dir}/{file_name}", "w", encoding="utf-8") as f:
            f.write(cell_code)