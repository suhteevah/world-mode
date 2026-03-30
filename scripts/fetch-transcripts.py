"""Fetch remaining Nilaus masterclass transcripts.
Run periodically until all 91 are done.
Usage: python scripts/fetch-transcripts.py
"""
from youtube_transcript_api import YouTubeTranscriptApi
import json, re, os, sys, time

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/nilaus-masterclass/video-list.json', 'r', encoding='utf-8') as f:
    videos = json.load(f)

outdir = 'docs/nilaus-vault'
api = YouTubeTranscriptApi()

need = []
for i, video in enumerate(videos):
    num = i + 1
    files = [f for f in os.listdir(outdir) if f.startswith(f'{num:02d}-') and f.endswith('.md')]
    if files and os.path.getsize(os.path.join(outdir, files[0])) < 200:
        need.append((num, video, files[0]))

print(f'{len(need)} remaining')
if not need:
    print('All done!')
    sys.exit(0)

for num, video, filename in need:
    time.sleep(60)
    vid_id = video['id']
    print(f'{num}: {video["title"][:50]}...', end=' ', flush=True)
    try:
        transcript = api.fetch(vid_id)
        lines = []
        for entry in transcript:
            ts = int(entry.start)
            lines.append(f'[{ts//60:02d}:{ts%60:02d}](https://youtu.be/{vid_id}?t={ts}) {entry.text}')
        with open(os.path.join(outdir, filename), 'w', encoding='utf-8') as f:
            f.write(f'# {video["title"]}\n')
            f.write(f'Video: https://www.youtube.com/watch?v={vid_id}\n\n')
            f.write('\n'.join(lines))
        print(f'OK ({len(lines)})')
    except Exception as e:
        print(f'ERR: {type(e).__name__}')
        if 'Blocked' in str(type(e).__name__):
            print('IP blocked. Try again later.')
            break

has = sum(1 for f in os.listdir(outdir) if f.endswith('.md') and os.path.getsize(os.path.join(outdir, f)) > 200)
print(f'\nTotal: {has}/91')
