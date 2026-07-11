# Terraform Interview Master List

## Fundamentals

1. What problem does infrastructure as code solve?
2. What is the difference between declarative and imperative infrastructure management?
3. Explain Terraform plan, apply, and state.
4. Why should state be protected?

## HCL and modules

5. How do variables, locals, outputs, and modules work together?
6. When would you split code into a module?
7. What makes a module interface stable?
8. How do you handle optional inputs?

## State and collaboration

9. Why use remote state?
10. How does locking prevent incidents?
11. What is drift and how do you detect it?
12. When is `terraform state mv` appropriate?

## AWS architecture

13. How would you design a VPC for production?
14. Why place ECS tasks in private subnets?
15. How should RDS access be restricted?
16. What logs should be centralized?

## Security

17. How do you manage secrets in Terraform workflows?
18. What IAM permissions should CI have?
19. What should a security scan catch before apply?
20. Why should production applies be gated?

## Advanced Terraform

21. Compare `count` and `for_each`.
22. Explain `dynamic` blocks.
23. Why use `jsonencode`?
24. How do import blocks work?
25. How do moved blocks prevent recreation during refactors?
26. When would you build a custom provider?

## Ecosystem

27. What does Terragrunt solve?
28. When would you choose Atlantis?
29. Compare Terraform Cloud and Spacelift.
30. What is OpenTofu?
31. Where does Infracost fit in CI/CD?

## Enterprise design

32. Why use multiple AWS accounts?
33. What belongs in a security account?
34. What belongs in a logging account?
35. How do you design backup and disaster recovery for RDS?
36. How do you migrate from a monolithic Terraform codebase to modules?

## Senior-level scenarios

37. A Terraform plan wants to replace a production database. What do you do?
38. A team manually changed a security group in AWS. How do you respond?
39. CI cannot acquire a state lock. What do you investigate?
40. Your module has too many feature flags. How do you simplify it?
