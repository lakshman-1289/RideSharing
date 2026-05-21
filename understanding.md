.\run.bat

Step 1: Service Registry Foundation
Start with 

EurekaServerApplication.java
. This is the service discovery server that holds the system registry.

```
we need a central directory.
That directory is:
Netflix Eureka

Eureka is a:
Service Registry + Discovery Server
"Eureka Server is a centralized service registry where microservices dynamically register themselves and discover other running services without hardcoded IP addresses or ports."

```


Step 2: The Gateway and Security
Read 

GatewayConfig.java
 to understand how client endpoints translate to downstream services.
Look at 

JwtAuthenticationFilter.java
 to see how authorization headers are intercepted, validated, and converted into downstream headers like X-User-Id.

```
1. Dynamic Routing Config: GatewayConfig.java
This class programmatically defines routing rules, binding URL path patterns to backend service identifiers registered in Eureka.

2. Centralized CORS Filter: SecurityConfig.java
Cross-Origin Resource Sharing (CORS) security is handled strictly at the gateway to prevent duplicate header conflicts.

"A filter is:
A component that intercepts requests and responses before they reach the actual controller/service.
It acts like a checkpoint in the request flow."

"Spring Cloud Gateway is built on:
Spring WebFlux
NOT traditional Spring MVC.

Reactive systems are:
asynchronous
non-blocking
event-driven
So methods don't return values immediately.

Instead they return:
Future/Promise-like reactive objects
In WebFlux:
Type	Meaning
Mono<T>	0 or 1 async result
Flux<T>	Multiple async results"

The filter chain proceeds sequentially, but asynchronously means the thread is not blocked while waiting for operations like network calls, authentication, or IO to complete.-> explains webflux returns mono/flux functionality

3. Boundary Token Verification: JwtAuthenticationFilter.java
This is a Global Filter that runs on every request. It intercepts, parses, and validates the caller's identity before forwarding requests downstream

4. JWT Extraction Helper: 
JwtUtil.java
Encapsulates token decryption and validation utility routines.

5. Non-Blocking Logger: LoggingFilter.java
Logs requests and calculates response latencies globally across all proxied microservices.

```

Step 3: Base Domain Service (Identity)
Open 
user-service
. Read 
User.java
 and 
Vehicle.java
 to understand the base domain entities.
Review 
AuthController.java
 and 
AuthService.java
 to see how accounts are created and authenticated.

 

Step 4: Core Core Domain Service (Rides & Bookings)
Open 

ride-service
. Read 

Ride.java
 and 

Booking.java
.
Study 

RideController.java
 to see the endpoints for creating, searching, and booking rides.
Inspect 

UserServiceClient.java
 to see how domain data is dynamically enriched from other microservices using OpenFeign.
Step 5: Transactional Domain Service (Payments)
Open 

payment-service
. Read 

Payment.java
.
Study 

PaymentController.java
 and 

PaymentService.java
 to understand how Razorpay triggers payment states.
Step 6: Client Application (UI Integration)
Go to the React frontend 

fronted_ride_share
.
Look at 

endpoints.js
 to see how paths map directly to the Gateway endpoints.
Review 

apiClient.js
 to see how JWT refresh logic and interceptors attach tokens globally.