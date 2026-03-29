path = r'c:/Users/Djafari/Documents/capstone/mama_safe/lib/presentation/screens/chw/chat_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the broken pattern and fix it
content = content.replace(
    '  }\n\n    try {\n\n      print(\'🔗 Attempting to connect to chat...',
    '  }\n\n  Future<void> _connectToChat() async {\n    try {\n\n      print(\'🔗 Attempting to connect to chat...'
)

# Also try with the garbled emoji version
import re
content = re.sub(
    r'  \}\n\n    try \{\n\n      print\(\'[^\']*Attempting to connect to chat\.\.\.',
    "  }\n\n  Future<void> _connectToChat() async {\n    try {\n\n      print('🔗 Attempting to connect to chat...",
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if '_connectToChat' in line or 'Attempting to connect' in line:
        print(f'{i+1}: {line.rstrip()}')
