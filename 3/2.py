lines = []
with open('input.txt') as f:
    lines = f.readlines()

sum = 0
for line in lines:

    prev_max_idx = 0
    line_result: str = ""

    for i in reversed(range(1, 13)):
        max_idx = 0
        max_value = '0'

        for i, e in enumerate(line[prev_max_idx:-i]):
            if int(e) > int(max_value):
                max_value: str = e
                max_idx = i + 1

        prev_max_idx += max_idx
        line_result += max_value

    print(line_result)
    sum += int(line_result)
print(sum)

