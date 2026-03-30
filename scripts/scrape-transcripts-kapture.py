"""
Scrape remaining YouTube transcripts using Kapture browser automation.
Navigates to each video, clicks the YTT copy button, reads clipboard via PowerShell.
"""
import json, os, sys, subprocess, time, re

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/nilaus-masterclass/video-list.json', 'r', encoding='utf-8') as f:
    videos = json.load(f)

outdir = 'docs/nilaus-vault'
need = []
for i, v in enumerate(videos):
    num = i + 1
    files = [f for f in os.listdir(outdir) if f.startswith(f'{num:02d}-') and f.endswith('.md')]
    if files and os.path.getsize(os.path.join(outdir, files[0])) < 200:
        need.append((num, v['id'], v['title'], files[0]))

print(f'{len(need)} episodes remaining')

# This script assumes Kapture is connected and the tab is ready.
# Run the navigate/click/read cycle for each video.
# Since we can't call Kapture MCP from Python directly,
# we output commands that the parent process should execute.

for num, vid_id, title, filename in need:
    safe_title = re.sub(r'[^\w\s-]', '', title)[:80].strip()
    print(f'FETCH:{num}:{vid_id}:{filename}')
