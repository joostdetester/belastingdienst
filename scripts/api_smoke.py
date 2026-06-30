import requests
import os


BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8001")


def main() -> None:
    health = requests.get(f"{BASE_URL}/health", timeout=10)
    health.raise_for_status()
    print("Health:", health.json())

    payload = {"jaarinkomen": 52000, "aftrek": 3000}
    tax = requests.post(f"{BASE_URL}/belasting/bereken", json=payload, timeout=10)
    tax.raise_for_status()
    print("Tax result:", tax.json())


if __name__ == "__main__":
    main()
