import json
import unittest

from handler import handler


class TestHandler(unittest.TestCase):

    def test_health_response(self):
        response = handler({}, None)

        self.assertEqual(response["statusCode"], 200)

        body = json.loads(response["body"])

        self.assertEqual(body["status"], "ok")
        self.assertEqual(body["version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()