
'''
Author: Logan.Li
Gitee: https://gitee.com/attacker
email: admin@attacker.club
Date: 2024-12-28 12:11:49
LastEditTime: 2025-09-02 17:04:27
Description: 批量替换目录下所有文件中的字符串
命令: python r.py -o old_string -n new_string
'''
import os
import logging
import argparse

def search_and_replace(directory, old_str, new_str):
    logging.basicConfig(filename='replace.log', level=logging.INFO)
    for root, _, files in os.walk(directory):
        for file in files:
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r+', encoding='utf-8') as f:
                    content = f.read()
                    if old_str in content:
                        content = content.replace(old_str, new_str)
                        f.seek(0)
                        f.write(content)
                        f.truncate()
                        logging.info(f"Replaced '{old_str}' with '{new_str}' in file: {filepath}")
            except Exception as e:
                logging.error(f"Error processing file {filepath}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Replace strings in all files in a directory.')
    parser.add_argument('-o', '--old', required=True, help='Old string to be replaced.')
    parser.add_argument('-n', '--new', required=True, help='New string to replace with.')
    args = parser.parse_args()

    directory = os.getcwd()
    search_and_replace(directory, args.old, args.new)