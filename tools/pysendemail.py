import smtplib
from typing import Union

def init_SMTP_client(mode: str, configs: dict) -> Union[smtplib.SMTP_SSL, smtplib.SMTP]:
    if mode == 'ssl':
        server = smtplib.SMTP_SSL(configs['smtp_host'], 465)
        server.set_debuglevel(configs["debug"])
        server.ehlo()
    elif mode == 'tls':
        server = smtplib.SMTP(configs['smtp_host'], 587)
        server.set_debuglevel(configs["debug"])
        server.ehlo()
        server.starttls()
    else:
        server = smtplib.SMTP(configs['smtp_host'], 25)
        server.set_debuglevel(configs["debug"])
    return server


if __name__ == '__main__':

    targets = []
    with open('recipients.txt') as f:
        targets = f.read().split("\n")

    configs = []
    with open('.env') as f:
        configs = f.read().split("\n")

    conf = dict()
    for line in configs:
        try:
            conf[line.split("=")[0]] = line.split("=")[1]
        except Exception as e:
            print(f"Error parsing conf variable: {line}: {e.args[::-1]}")

    print(conf)


    config = {
        "smtp_host": conf["SMTP_HOST"],
        "user": conf["SMTP_USER"],
        "addressed_user": "Some Name",
        "targets": targets,
        "password": conf["SMTP_PASSWORD"],
        "mode": conf["SMTP_MODE"],
        "debug": 1,
        "subject": "WARNING"
    }

    message = f"""From: <{config['user']}>\r\nTo: <{config['targets']}>
    Subject: {config['subject']}
    Hello {config['addressed_user']},

    Your account has been compromised!

    We are investigating and taking measures in this breach case. We will further notify you when we resolve this issue.
    Until we resolve this, You need to urgently protect your account via provided link: http://127.0.1.1:45666

    Please take this issue seriously.
    Thank you for your understanding and we apologize for the incoveniance.

    Best Regards
    """
    try:
        smtp_server = init_SMTP_client(mode=config['mode'], configs=config)
        smtp_server.login(config['user'], config['password'])
        smtp_server.sendmail(from_addr=config['user'], to_addrs=config['targets'], msg=message)
        smtp_server.quit()
        print(f"Mail sent successfuly to: {config['targets']}")
        exit(0)
    except Exception as e:
        print(f"Failed to send mail to: {config['targets']}\r\nError >>> {e.args[::-1]}")
        exit(1)
