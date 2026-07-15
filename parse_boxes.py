import sys

def main():
    with open('yeni_deneme_kutu_islemleri.mq5', 'r') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if "DoDrawBox" in line and not "void DoDrawBox" in line:
            print(f"{i}: {line.strip()}")

if __name__ == '__main__':
    main()
