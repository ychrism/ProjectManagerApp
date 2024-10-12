from django.core.management.base import BaseCommand
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.contrib.auth.password_validation import validate_password
from api.models import TheUser

class Command(BaseCommand):
    help = 'Creates a custom admin user'

    def add_arguments(self, parser):
        parser.add_argument('--email', type=str, help='Email for the admin user')
        parser.add_argument('--first_name', type=str, help='First name of the admin user')
        parser.add_argument('--last_name', type=str, help='Last name of the admin user')
        parser.add_argument('--password', type=str, help='Password for the admin user')

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING('Create Custom Admin User'))

        email = options['email'] or self.get_input('Email')
        while self.email_exists(email):
            self.stderr.write('Error: That email is already in use.')
            email = self.get_input('Email')

        first_name = options['first_name'] or self.get_input('First name')
        last_name = options['last_name'] or self.get_input('Last name')

        password = options['password']
        if not password:
            while True:
                password = self.get_password()
                try:
                    validate_password(password)
                    break
                except ValidationError as e:
                    self.stderr.write('\n'.join(e.messages))
        else:
            try:
                validate_password(password)
            except ValidationError as e:
                self.stderr.write('\n'.join(e.messages))
                return

        try:
            user = TheUser.objects.create_admin(
                email=email,
                first_name=first_name,
                last_name=last_name,
                password=password
            )
            self.stdout.write(self.style.SUCCESS(f'Admin user created successfully: {user.email}'))
        except IntegrityError:
            self.stderr.write(self.style.ERROR('Error creating user. Please try again.'))

    def get_input(self, prompt):
        return input(f'{prompt}: ')

    def get_password(self):
        while True:
            password = input('Password: ')
            password_confirm = input('Password (again): ')
            if password != password_confirm:
                self.stderr.write("Error: Your passwords didn't match.")
                continue
            return password

    def email_exists(self, email):
        return TheUser.objects.filter(email=email).exists()