# print_urls.py

from django.urls import get_resolver
from django.core.management.base import BaseCommand

def print_url_names():
    resolver = get_resolver()
    for url_pattern in resolver.url_patterns:
        if hasattr(url_pattern, 'name'):
            print(f"Name: {url_pattern.name}, Pattern: {url_pattern.pattern}")
        if hasattr(url_pattern, 'url_patterns'):
            for sub_pattern in url_pattern.url_patterns:
                if hasattr(sub_pattern, 'name'):
                    print(f"Name: {sub_pattern.name}, Pattern: {url_pattern.pattern}{sub_pattern.pattern}")

# If you want to run this as a management command:
class Command(BaseCommand):
    help = 'Prints all named URL patterns'

    def handle(self, *args, **options):
        print_url_names()

# To run this script directly:
if __name__ == '__main__':
    import django
    django.setup()
    print_url_names()
