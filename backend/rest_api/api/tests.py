from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase
from .models import TheUser, Board, Card
from datetime import datetime
from django.core.management import call_command


class BaseAPITestCase(APITestCase):
    # Class-level counter for generating unique emails
    test_counter = 0

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.test_counter = 0

    def setUp(self):
        # Increment the counter for each test
        self.__class__.test_counter += 1

        # Generate unique emails for each test
        user_email = f'testuser1@example.com'
        admin_email = f'admin{self.test_counter}@example.com'

        self.user_creds = {
            'email': user_email,
            'first_name': f'Test1',
            'last_name': f'User1',
            'password': 'password123'
        }
        self.admin_creds = {
            'email': admin_email,
            'first_name': f'Admin{self.test_counter}',
            'last_name': f'User{self.test_counter}',
            'password': 'adminpassword123'
        }
        
        # Create user and admin
        self.user = TheUser.objects.create_user(
            email=self.user_creds['email'],
            first_name=self.user_creds['first_name'],
            last_name=self.user_creds['last_name'],
            password=self.user_creds['password']
        )
        self.admin = TheUser.objects.create_admin(
            email=self.admin_creds['email'],
            first_name=self.admin_creds['first_name'],
            last_name=self.admin_creds['last_name'],
            password=self.admin_creds['password']
        )
        
        # Authenticate and store tokens
        self.user_jwt = self.get_jwt_token(self.user_creds)
        self.admin_jwt = self.get_jwt_token(self.admin_creds)



    def get_jwt_token(self, credentials):
        response = self.client.post(reverse('get_token'), {
            'email': credentials['email'],
            'password': credentials['password']
        }, format='json')
        return response.data['access']

    def authenticate_as_user(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.user_jwt}')

    def authenticate_as_admin(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.admin_jwt}')

class TheUserAPITest(BaseAPITestCase):
    def test_signup(self):
        response = self.client.post(reverse('signup'), self.user_creds)
        print(response.data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_login_success(self):
        for creds in [self.user_creds, self.admin_creds]:
            response = self.client.post(reverse('get_token'), {
                'email': creds['email'],
                'password': creds['password']
            }, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_login_failure(self):
        for creds in [self.user_creds, self.admin_creds]:
            response = self.client.post(reverse('get_token'), {
                'email': creds['email'],
                'password': 'wrongpassword'
            }, format='json')
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_get_users(self):
        self.authenticate_as_user()
        response = self.client.get(reverse('users-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 2)

class BoardAPITest(BaseAPITestCase):
    def setUp(self):
        super().setUp()
        self.board_id = self.create_board()

    def create_board(self):
        self.authenticate_as_admin()
        with open('/home/mcluffy99/Pictures/logo.jpg', "rb") as pic_file:
            data = {
                'name': 'Test Board',
                'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),
                'due_date': timezone.make_aware(datetime(2024, 1, 10, 0, 0, 0)),
                'description': 'A test board',
                'progress': 0,
                'pic': pic_file
            }
            response = self.client.post(reverse('boards-list'), data, format='multipart')
        return response.data['id']

    def test_create_board_as_admin(self):
        self.authenticate_as_admin()
        with open('/home/mcluffy99/Pictures/logo.jpg', "rb") as pic_file:
            data = {
                'name': 'Another Test Board',
                'start_date': timezone.make_aware(datetime(2024, 2, 1, 0, 0, 0)),
                'due_date': timezone.make_aware(datetime(2024, 2, 10, 0, 0, 0)),
                'description': 'Another test board',
                'progress': 0,
                'pic': pic_file
            }
            response = self.client.post(reverse('boards-list'), data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        

    def test_board_retrieval_as_authenticated_user_not_member(self):
        self.authenticate_as_user()
        url = reverse('boards-detail', args=[self.board_id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_board_retrieval_as_admin(self):
        self.authenticate_as_admin()
        url = reverse('boards-detail', args=[self.board_id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_board_retrieval_as_unauthenticated_user(self):
        self.client.credentials()  # Clear authentication
        url = reverse('boards-detail', args=[self.board_id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_create_board_as_member(self):
        self.authenticate_as_user()
        with open('/home/mcluffy99/Pictures/logo.jpg', "rb") as pic_file:
            data = {
                'name': 'Test Board',
                'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),
                'due_date': timezone.make_aware(datetime(2024, 1, 10, 0, 0, 0)),
                'description': 'A test board',
                'progress': 0,
                'pic': pic_file
            }
            response = self.client.post(reverse('boards-list'), data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_update_board_as_admin(self):
        self.authenticate_as_admin()
        with open('/home/mcluffy99/Pictures/logo.jpg', "rb") as pic_file:
            data = {
                'start_date': timezone.make_aware(datetime(2024, 2, 1, 0, 0, 0)),
                'due_date': timezone.make_aware(datetime(2024, 2, 20, 0, 0, 0)),
                'description': 'Another test board',
                'progress': 1,
            }
            response = self.client.patch(reverse('boards-detail', args=[self.board_id]), data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_delete_board_as_admin(self):
        self.authenticate_as_admin()
        response = self.client.delete(reverse('boards-detail', args=[self.board_id]))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

class CardAPITest(BaseAPITestCase):
    def setUp(self):
        super().setUp()
        self.board_id = self.create_board()
        self.card_id = self.create_card()

    def create_board(self):
        self.authenticate_as_admin()
        with open('/home/mcluffy99/Pictures/logo.jpg', "rb") as pic_file:
            data = {
                'name': 'Test Board',
                'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),
                'due_date': timezone.make_aware(datetime(2024, 1, 10, 0, 0, 0)),
                'description': 'A test board',
                'progress': 0,
                'pic': pic_file
            }
            response = self.client.post(reverse('boards-list'), data, format='multipart')
        return response.data['id']

    def create_card(self):
        self.authenticate_as_admin()
        data = {
            'title': 'New Card',
            'priority': 'HIGH',
            'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),
            'due_date': timezone.make_aware(datetime(2024, 1, 3, 0, 0, 0)),
            'description': 'A new test card',
            'board': self.board_id,
            'status': 'TODO',
            'emails': ["testuser1@example.com","testuser1@exemple.com"]
        }
        response = self.client.post(reverse('cards-list'), data, format='json')
        return response.data['id']

    def test_create_card(self):
        self.authenticate_as_admin()
        data = {
            'title': 'Another Card',
            'priority': 'LOW',
            'start_date': timezone.make_aware(datetime(2024, 1, 5, 0, 0, 0)),
            'due_date': timezone.make_aware(datetime(2024, 1, 7, 0, 0, 0)),
            'description': 'Another test card',
            'board': self.board_id,
            'status': 'TODO',
            'emails': ["testuser1@example.com","testuser2@exemple.com"]
        }
        response = self.client.post(reverse('cards-list'), data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        card = Card.objects.get(id=response.data['id'])
        self.assertEqual(card.members.count(), 1)
        self.assertTrue(card.members.filter(email='testuser1@example.com').exists())


    def test_update_card_root_level(self):
        TheUser.objects.create_user(**{
            'email': 'yvescmedagbe@gmail.com',
            'first_name': 'Test19',
            'last_name': 'User19',
            'password': 'password123'
        })
        TheUser.objects.create_user(**{
            'email': 'yvescmedagbe4@gmail.com',
            'first_name': 'Test149',
            'last_name': 'User149',
            'password': 'password1234'
        })
        self.authenticate_as_admin()
        url = reverse('cards-detail', args=[self.card_id])
        data = {
            'title': 'Updated Card Title',
            'description': 'Updated description',
            'priority': 'HIGH',
            'board': self.board_id,
            'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),            
            'due_date': timezone.make_aware(datetime(2024, 1, 3, 0, 0, 0)),
            'status': 'DOING',
            'emails': ['yvescmedagbe@gmail.com', 'yvescmedagbe4@gmail.com']
        }
        response = self.client.put(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        card = Card.objects.get(id=response.data['id'])
        self.assertEqual(card.members.count(), 2)
        self.assertEqual(card.board.members.count(), 2)
        self.assertTrue(card.members.filter(email='yvescmedagbe@gmail.com').exists())
        self.assertTrue(card.members.filter(email='yvescmedagbe4@gmail.com').exists())

    
    def test_update_card_member_level(self):
        TheUser.objects.create_user(**{
            'email': 'yvescmedagbe@gmail.com',
            'first_name': 'Test19',
            'last_name': 'User19',
            'password': 'password123'
        })
        TheUser.objects.create_user(**{
            'email': 'yvescmedagbe4@gmail.com',
            'first_name': 'Test149',
            'last_name': 'User149',
            'password': 'password1234'
        })
        self.authenticate_as_user()
        url = reverse('cards-detail', args=[self.card_id])
        data = {
            'title': 'Updated Card Title',
            'description': 'Updated description',
            'priority': 'HIGH',
            'board': self.board_id,
            'start_date': timezone.make_aware(datetime(2024, 1, 1, 0, 0, 0)),            
            'due_date': timezone.make_aware(datetime(2024, 1, 3, 0, 0, 0)),
            'status': 'DONE',
            'emails': ['yvescmedagbe@gmail.com', 'yvescmedagbe4@gmail.com']
        }
        response = self.client.put(url, data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        response = self.client.patch(url, {'status':'DONE'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)


    def test_delete_card(self):
        self.authenticate_as_admin()
        url = reverse('cards-detail', args=[self.card_id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

# You can similarly refactor MessageAPITest and GroupMessageAPITest