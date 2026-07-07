from itertools import chain
from yt_dlp.extractor.bilibili import BiliBiliIE
from yt_dlp.utils import traverse_obj
from urllib.parse import urlparse, parse_qs


class BilibiliCDNIE(BiliBiliIE):

    def _select_url(self, urls):
        first_url = None

        for url in urls:
            if first_url is None:
                first_url = url
            parsed_url = urlparse(url)
            query = parse_qs(parsed_url.query)
            if 'os' in query and query['os'] != ['mcdn']:
                return url

        # fallback
        return first_url

    def extract_formats(self, play_info):

        audios = traverse_obj(play_info, ('dash', (None, 'dolby'), 'audio', ..., {dict})) or []
        flac_audio = traverse_obj(play_info, ('dash', 'flac', 'audio')) or []
        videos = traverse_obj(play_info, ('dash', 'video', ...)) or []

        for obj in chain(audios, flac_audio, videos):
            base_url = traverse_obj(obj, 'baseUrl', 'base_url', 'url')
            if type(base_url) is not str:
                continue

            backup_url = traverse_obj(obj, 'backupUrl', 'backup_url')
            if type(backup_url) is not list:
                continue

            selected_url = self._select_url([base_url, *backup_url])
            obj['base_url'] = selected_url
            obj['baseUrl'] = selected_url
            obj['backup_url'] = []
            obj['backupUrl'] = []

        return super().extract_formats(play_info)
