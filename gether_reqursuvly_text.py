import os

def collect_files_content(root_folder, output_file):
    with open(output_file, 'w', encoding='utf-8') as result_file:
        for foldername, subfolders, filenames in os.walk(root_folder):
            for filename in filenames:
                file_path = os.path.join(foldername, filename)
                result_file.write(f"## {file_path}\n\n")
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    result_file.write(content)
                    result_file.write("\n\n")

root_folder = 'lib'  # Задайте шлях до вашої папки
output_file = 'resultq.md'
collect_files_content(root_folder, output_file)
