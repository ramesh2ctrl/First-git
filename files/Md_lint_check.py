from pathlib import Path
import subprocess
import argparse
import json
import re


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--name", action="store",
                        dest="repo_name", default=None)
    args = parser.parse_args()

    if args.repo_name is None:
        raise Exception("Failed to get repo name!")

    paths = []
    problems_dict = {}

    for path in Path(args.repo_name).rglob('*.md'):
        if "generated/release_notes/" not in str(path):
            paths.append(str(path))

    with open("rules.rb", "w") as rules_file:
        rules_file.write(
            "all\nexclude_rule 'MD007'\nexclude_rule 'MD013'\nexclude_rule 'MD029'\nexclude_rule 'MD033'\nrule 'MD009', :br_spaces => 2\n")

    for path in paths:
        # Run mdl with style specified on each .md file and catch the output
        result = subprocess.run(
            ['mdl', '-s', 'rules.rb', path], stdout=subprocess.PIPE)

        # Split the output into separate lines
        problems = result.stdout.decode("utf-8").split("\n")

        # Filter out empty elements ('')
        problems = list(filter(('').__ne__, problems))

        if len(problems) != 0:
            # If there are linting problems, at the end of each output from mdl, there is a
            # "A detailed description of the rules is available at https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md"
            # We dont want this message in the report of found problems, so we delete it.
            del problems[-1]
            problems_dict[path] = []

        for problem in problems:
            # input to re.split looks like (example):
            # /CE-Documentation/indexmd:1084: MD034 Bare URL used
            regex_out = re.split(r".md\:(.*?)\:\s", problem)
            if len(regex_out) == 3:
                line = regex_out[1]
                description = regex_out[2]

                problems_dict[path].append({
                    f"line:{line}": description
                })
            else:
                raise Exception(
                    "Failed to separate problem line number and description!")

    if problems_dict == {}:
        print("True")

    with open("problems.json", "w") as outfile:
        json_object = json.dumps(problems_dict, indent=4)
        outfile.write(json_object)


if __name__ == "__main__":
    main()