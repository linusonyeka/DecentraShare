# DecentraShare - Decentralized Social Media Platform

DecentraShare is a decentralized social media platform built on the Stacks blockchain using Clarity smart contracts. It enables users to create posts, follow other users, like and tip content, and maintain their profiles in a decentralized manner.

## Features

- **Decentralized Posts**: Users can create and share content that lives on the blockchain
- **Profile Management**: Create and update user profiles with customizable usernames and bios
- **Social Interactions**: Follow other users and engage with their content
- **Economic Incentives**: Tip creators with STX tokens to support their content
- **Content Engagement**: Like and interact with posts from other users

## Smart Contract Functions

### Post Management
- `create-post`: Create a new post with content (max 500 characters)
- `like-post`: Like an existing post
- `tip-post`: Send STX tokens to content creators
- `get-post`: Retrieve post details

### Profile Management
- `set-profile`: Create or update user profile
- `get-profile`: Retrieve user profile information

### Social Features
- `follow-user`: Follow another user
- `is-following`: Check if one user follows another

## Technical Details

### Data Structures

1. Posts Map:
```clarity
{
    post-id: uint,
    author: principal,
    content: string-utf8,
    timestamp: uint,
    likes: uint,
    tips: uint
}
```

2. User Profiles Map:
```clarity
{
    username: string-utf8,
    bio: string-utf8,
    followers: uint,
    following: uint
}
```

### Error Codes

- `ERR-NOT-AUTHORIZED (u1)`: User not authorized for action
- `ERR-POST-NOT-FOUND (u2)`: Referenced post doesn't exist
- `ERR-INVALID-CONTENT (u3)`: Invalid content format or empty content

## Development

### Prerequisites

- Stacks blockchain development environment
- Clarity CLI tools
- Compatible wallet for testing (e.g., Hiro Wallet)

### Testing

1. Deploy the contract to the Stacks testnet
2. Use the provided function calls to test functionality
3. Verify social interactions and token transfers

### Security Considerations

- Content validation to prevent spam
- Principal-based authorization
- Safe STX transfer handling

## Future Enhancements

1. Content moderation mechanisms
2. Enhanced profile features
3. Comment system implementation
4. Content categories and tags
5. Decentralized content storage integration
