---
layout: post
title: "Prevent account sharing with MFA"
headline: "Prevent account sharing with MFA"
modified: 2024-03-14 15:57:54 +0100
description: "Learn how Multi Factor Authentication (MFA) can help you prevent account sharing and unauthorized access to your data."
tags: [metabase]
featured_post: false
toc: true
image: fingerprint.png
---

TL;DR: MFA increased our app new signups by 30% daily. It can help you but measure the impact of the changes.

Preventing account sharing in your app is vital. Different methods tackle this. Recently, we've been focusing on the issue. We discovered a simple, low-risk fix. It protects revenue and boosts security. Also, it aids in generating dynamic reports. This solution allows us to track data. It helps manage violation cases. Check out how we achieved this.

## Why to prevent sharing account

Sharing an account is one of the backdoors that leads to financial losses. Instead of having paid two users who are friends in your app, you have only one. They buy one account and share credentials, resulting in underpaying the business.

Another aspect of preventing sharing accounts is security. Someone might steal a user's credentials. The thief will use the account, and nobody will know about it.

![MFA is for security](/images/security.jpg)

All of that is very important indeed. However, our primary goal was to boost app revenue.


## Prevent account sharing with a third-party service

Some services promise to solve the issue with account sharing in your product. That option might sound like a good choice. Relying on their implementation, you sign up. Then, you configure your app by following their instructions and enjoying it. Sounds easy and fantastic. Yet, some disadvantages can prevent you from following this path.

To start, consider how these services tackle the problem. They track user actions. These include clicks, mouse movements, IP addresses, device types, and locations. If the user's behavior deviates from the norm, the service flags it as suspicious. While effective, there are limitations to this approach. It hinges on a vast amount of user data. The more data and users they have, the more accurate the service becomes. The law of large numbers must function. But you never know if they have enough data. They also need to know your app data and users. Hence, the conclusions about sharing an account might be wrong. In the end, remember that there will always be false positives. It's essential to have a plan to address them.

This solution takes time to set up and integrate. Dealing with false positives is challenging. You need custom logic to link this service to your app. You lose control over valuable data to improve your product. Also, there's a fee that may not suit long-term needs. Comparing it to your solution is necessary.

We aimed for user session control, limiting per-user sessions. Account sharing was still possible. The system permitted a fixed number of simultaneous sessions. A user accessing the app on various devices led us here. Working with a third-party service brought obstacles here. Thus, we chose to drop this method.

## Our path to a solution for preventing account sharing

As the first step, many recommend using multi-factor authentication (MFA) and stopping there. Indeed, it's an excellent option to consider. We definitely should implement it. Yet, how can we be sure it helps? How can we prevent user loss after enabling MFA? Each app community is different. Their expectations may vary. Enabling MFA for all for no reason could alienate many users. They may leave the app, hurting the business.

Hence, we need indicators to track the impact of our changes on user behavior. Yet, we must decide who gets MFA enabled and assess whether account-sharing prevention works. Thus, an imaginary "violations per user" is a crucial indicator to track. Ultimately, it aligns with login sessions per user—the fewer active login sessions a user has, the fewer violations.
If all goes well, the "violations per user" indicator should drop after enabling MFA. Additionally, we expect more users to sign up. Some users using the shared account should eventually sign up for the app. Moreover, the number of active users should not drop. If all that happens, that would mean the feature works well and improves things rather than hurting the business.

We can easily track the number of new signups and the number of active users without changing the app. Having direct access to the database, we can do that with relatively easy SQL queries.

However, we do not have data for the "violations per user" indicator. Thus, we should implement a solution for that.

Thinking this way, we come up with the following initial ideas:
- Analyze the user agent's IP and device type in the web server logs. Create a report of suspicious user actions such as often IP change or device type.
- Then, if every subsequent request differs from what's inside the cookies, it's a violation.
- After analyzing these reports, come up with an idea of who should have MFA enabled. Eventually, implement MFA for them.

![Bright idea](/images/idea-bulb.jpg)

## Solution #1: logs analysis

Looking into logs and checking how many unique IPs and devices one user uses is a natural solution that comes to mind. We have implemented it. However, this solution did not derive a "sharing account violations" indicator. The story behind this deserves a separate post. In short, it was a challenging task. Based on this data, we've had many false positive reports.
This is a challenge for us and giants like Google, LastPass, and even your local banks. For that reason, you get a lot of irritating emails every time you log in to these services. I do, and I have it. Our users could hate it as well. A more straightforward solution should correctly identify the fact of sharing accounts.

## Solution #2: unique token per device written in cookies

If we have to limit the users' login sessions, we could restrict them by device type. We can issue a unique token per user device and store it in the DB along with other important information such as IP and the user agent (device info). The idea was to allow one user to use only one device of a specific type at a time. For example, one user can use one web login on a desktop and one on a mobile app. If someone else uses the same device type at the time, it's a violation. We successfully implemented this solution, and in fact, it worked well. There were some false positives. But fewer than in the previous solution. We could even stick with this solution. However, the business changed its mind and allowed a limited number of login sessions, independent of the device type.

Nevertheless, even though it's been rejected, this solution can still be used to implement the "sharing account violations" indicator. We use it to collect and analyze reports.

## Solution #3: login session concept

Using the experience of the previous solution, we implemented a modernized version that elaborated into a login session concept. The idea is the following. One user can have many login sessions. A login session is an entity with a unique token. It's created right after the user's login and deactivated after the user logs out. This unique token is injected into cookies. We search for an active login session in every subsequent request and create if it still needs to be added. A user with many such login sessions shares an account. And for them, we should enable MFA.

## Solution #4: device limit, limit of login sessions

Having the previous solution ready, we can limit the login sessions in the following way: Every time a user logs in, check if the number of login sessions is too big, say 4. If that's the case, prevent the user from going further and ask them to log in from some of the current login sessions. This is what we are implementing next.

![Active login sessions](/images/active-sessions.png)

## Our results, analysis, and reports

Now, we have the indicator that shows the dynamic of account sharing violations. We gradually enable MFA for those users with the most violations and check the following dynamics.

New signups and active users on a paid plan. Note that it includes users on a trial that lasts for 15 days. That's why there is this peak on the right side:

![Active login sessions](/images/prevent-account-sharing/active-users-report.png)

Sharing token reports dynamics:

![Token violations report](/images/prevent-account-sharing/token-violations-report.png)

The report dynamics are based on log analysis. It turned out to be useless, and for that reason, we will drop it:

![Log analyzed reports](/images/prevent-account-sharing/log-analyzed-reports.png)

Active login sessions per user with MFA enabled:

![MFA enabled reports](/images/prevent-account-sharing/otp-enabled-reports.png)

Active login sessions per user with MFA disabled:

![MFA disabled reports](/images/prevent-account-sharing/otp-disabled-reports.png)

Active login sessions for all users regardless of the MFA toggle. This one has the data combined with the 2 previous charts:

![Regardless MFA toggle reports](/images/prevent-account-sharing/average-per-user-reports.png)

Looking into these charts, we conclude that:
- The number of active paying users increases.
- The number of sharing account reports based on the token solution decreases. The regression line predicts a drop from 170 points to 120, almost a 30% drop when IP and device differ. That's a vast improvement!
- The number of login sessions per user decreases for users with MFA enabled. This improvement is significant compared to users with MFA disabled.

## Summary

In this post, you learned how the positive impact of MFA enabling in your project can be measured. Now, you know which metrics inside your app you should watch for to understand if your solution works and helps the business survive.

Finally, you got a beneficial insight — MFA positively impacts user behavior. It indeed prevents users from sharing accounts. The improvement is significant — roughly 30% more new signups. Additionally, it's a security improvement for your app. It is worth considering for your project. But keep in mind that your auditory can be different, so measure the impact.

In the next step, we will implement the login session limits. We expect an even more positive impact and will measure the results. Stay tuned!
