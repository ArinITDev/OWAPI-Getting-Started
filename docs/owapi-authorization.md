[← Back to README](../README.md)

# OWAPI Step-by-Step Authorization Guide

![docs](./Images/Overview/authorization-dialogue.png)
</br>*Figure 2: OrderWise API authorization dialogue.*

# What the dialogue is telling you 

The API uses **Bearer Token Authentication** and the .

## You need to generate a Bearer Token

Before making API requests, obtain a bearer token by calling the `Token/GetToken` endpoint with your Orderwise credentials Base64 encoded and prefixed with "Basic " :

```text
username:password Base64 encoded
```

Base64 encode the value and prepend it with `Basic` and supply it in the Authorization header.

### Example

```bash
curl -X GET "https://localhost:xxx/token/gettoken" \
  -H "Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ="
```

If you can follow the logic and the example there's no nead for you to read the step by step instructions below, however you might find them useful if you're not sure about something or are getting stuck trying to access the OWAPI for the first time.

## Step-by-Step Instructions 

1. Create a user in Orderwise
2. Convert the credentials to base64 encoded
3. Use the base64 encoded credentials to generate a bearer token
4. Test the bearer token

