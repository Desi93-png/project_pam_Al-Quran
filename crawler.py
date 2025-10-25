import requests
import json

def getSurah(surah):
resp = requests.get(f'https://equran.id/api/surat/{surah}')
if(resp.status_code = 200):
    data = resp.text
    f = open(f'assets/datas/surah/{surah}.json', 'a')
    f.write(data)
    f.close()

jsonObj = json.loads(data)
    if(jsonObj['surat_selanjutnya' ]):
        getSurah(jsonObj['nomor'] + 1)

getSurah(1)