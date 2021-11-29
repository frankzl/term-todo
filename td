#!/usr/bin/env python
import argparse
import random
import os
import sys
from datetime import date, timedelta
import datetime
from termcolor import colored
import json
from pathlib import Path

todo_path = Path("/home/lu/notes/todo")

def convertToCheckbox(item, X=False):
    return '- [X] ' + item if X else '- [ ] ' + item

def join(items, toCheckbox=False, X=False):
    modified = items
    if toCheckbox:
        modified = [ convertToCheckbox(t, X=X) for t in items]

    return '\n'.join(modified)

def printC(text, color=None, attrs=None, **kwargs):
    if color or attrs:
        print(colored(text, color, attrs=attrs), **kwargs)
    else:
        print(text, **kwargs)

def write_json(filename, obj):
    Path(filename).write_text(json.dumps(obj, indent=2))
    print("Wrote to ..." + str(filename))

def init_file(todo_path, today_str):
    todos = []
    
    fixed_todos = Path.read_text(todo_path / ".fixedTodos").split("\n")[:-1]
    printC(join(fixed_todos, toCheckbox=True), "blue")
    
    printC("What to DO today!", "green")
    todo_item = input("- [ ] ")
    while todo_item:
        todos.append(todo_item)
        todo_item = input("- [ ] ")
    
    todos = fixed_todos + todos
    
    printC("What's the PURPOSE today? ", "green")
    purpose = input("Today I will ")
    
    printC("Showtime! What are we playing today? ", "red", end="")
    nameOfTheDay = input("")

    data = {
        "Game": nameOfTheDay,
        "Do": todos,
        "Done": [],
        "Purpose": "Today I will " + purpose,
        "Reflect": None,
        "Remind": "",
        "Date": today_str
    }

    write_json(todo_path / (filename.with_suffix(".json")), data)

def getEntry(filename):
    with open(filename) as f:
        data = json.load(f)
    return data

def printEntry(obj):
    printC(obj["Game"], "green", ['bold'], end=" ")
    printC(f"({obj['Date']})", attrs=['dark'])
    if obj['Done']:
        printC(f" Done ({len(obj['Done'])})", "blue", ['bold'])
        printC(join(obj['Done'], toCheckbox=True, X=True), attrs=['dark'])
    if obj['Do']:
        printC(f" Do ({len(obj['Do'])})", "red", ['bold'])
        printC(join([f"{j} ({str(i)})" for i,j in enumerate(obj['Do'])], toCheckbox=True), "red")
    
def reflect(entry, filename, todo_path):
    entry['Do'].remove("reflect")
    entry['Done'].append("reflect")

    do = len(entry['Do'])
    done = len(entry['Done'])
    
    if not do:
        printC(f"Congrats! {done}/{do+done} completed!", "green", attrs=["bold"])
    else:
        printC(f" Do ({len(entry['Do'])})", "red", ['bold'])
        printC(join([f"{j} ({str(i)})" for i,j in enumerate(entry['Do'])], toCheckbox=True), "red")
        printC(f"{done}/{do+done} completed..", "red", attrs=["bold"])
        if input("Call it a day? (y/n)") == "n":
            return

    reflectObj = dict()
    printC(f"Wrapping up '{entry['Game']}' ({entry['Date']})" , "yellow")
    printC("Tired? (0-10)", "yellow", end=" ")
    reflectObj["fatigue"] = input()
    printC("Happy? (0-10)", "yellow", end=" ")
    reflectObj["happy"] = input()
    printC("Got stuff done? (0-10) ", "yellow", end=" ")
    reflectObj["productivity"] = input()
    printC("Stuff for tomorrow? ", "yellow", end=" ")

    reflectObj["reminder"] = input()
    printC("What went well? ", "yellow", end=" ")
    reflectObj["positive"] = input()
    printC(f"Your purpose today: {entry['Purpose']}\nChecked that off?", "green", attrs=["bold"])
    printC("What could've been better? ", "yellow", end=" ")
    reflectObj["improve"] = input()

    printC(" Up for a random question? (y/n) ", "green")
    if input() == "y":
        qs = Path.read_text(todo_path / ".questions").split("\n")[:-1]
        selected = random.randrange(0, len(qs))
        q = qs.pop(selected)
        Path(todo_path / ".questions").write_text("\n".join(qs))
        printC(q, "green", attrs=['bold'])
        reflectObj["question"] = q
        reflectObj["answer"] = input()
    else:
        printC("Have a good day/night. Peace ut.", "green")

    entry['Reflect'] = reflectObj
    write_json(filename, entry)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", '--add')
    parser.add_argument("-c", '--commit', nargs="+", type=int)
    parser.add_argument("-e", '--edit', action="store_true")
    parser.add_argument("-r", '--reflect', action="store_true")
    args = parser.parse_args()

    today = datetime.datetime.now() - timedelta(hours=1)
    today_str = today.strftime("%y-%m-%d")
    filename = todo_path / (today_str + ".json" )

    if not os.path.isfile(filename):
        yesterday = (datetime.datetime.now() - timedelta(days=1)).strftime("%y-%m-%d")
        yesterday_file = todo_path / (yesterday + ".json" )
        if os.path.isfile(yesterday_file):
            print("Reminder from yesterday: ")
            printC(getEntry(yesterday_file)['Reflect']['reminder'], "red")
                
        init_file(todo_path, today_str)
    else:
        filename = todo_path / filename
        entry = getEntry(filename)
        if args.add:
            entry['Do'].append(args.add)
            write_json(filename, entry)
        elif args.commit:
            entry = getEntry(filename)
            rest_do = []
            done = []
            for i, item in enumerate(entry["Do"]):
                if i in args.commit:
                    if item == "reflect":
                        printC(" You cannot commit 'reflect'", "red")
                        rest_do.append(item)
                    else:
                        done.append(item)
                else:
                    rest_do.append(item)
            entry['Do'] = rest_do
            entry['Done'] = entry['Done'] + done
            write_json(filename, entry)
        elif args.edit:
            os.system(f"vim {filename}")
        elif args.reflect:
            reflect(entry, filename, todo_path)
        else:
            printEntry(entry)

    
