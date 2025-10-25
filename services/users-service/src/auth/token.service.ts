import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

type JwtPayload = any;

@Injectable()
export class TokenService {
  constructor(private readonly jwt: JwtService) {}

  // Access token (short-lived)
  async signAccessToken(payload: JwtPayload) {
    return this.jwt.signAsync(payload, {
      expiresIn: '1h',
      secret: process.env.JWT_SECRET || 'dev-secret',
    });
  }

  // Refresh token (longer-lived)
  async signRefreshToken(payload: JwtPayload) {
    return this.jwt.signAsync(payload, {
      expiresIn: '7d',
      secret:
        process.env.JWT_REFRESH_SECRET ||
        process.env.JWT_SECRET ||
        'dev-secret',
    });
  }

  async verifyAccessToken(token: string): Promise<JwtPayload> {
    return this.jwt.verifyAsync<JwtPayload>(token, {
      secret: process.env.JWT_SECRET || 'dev-secret',
    });
  }

  async verifyRefreshToken(token: string): Promise<JwtPayload> {
    return this.jwt.verifyAsync<JwtPayload>(token, {
      secret:
        process.env.JWT_REFRESH_SECRET ||
        process.env.JWT_SECRET ||
        'dev-secret',
    });
  }
}
