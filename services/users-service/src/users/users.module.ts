import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from './schemas/user.schema';
import { JwtModule } from '@nestjs/jwt';
import { TokenService } from 'src/auth/token.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema }, // <-- registers token getModelToken('User')
    ]),
    JwtModule.register({
      global: true, // optional
      secret: process.env.JWT_SECRET || 'dev-secret', // use env in prod!
      signOptions: { expiresIn: '1h' },
    }),
  ],
  controllers: [UsersController],
  providers: [UsersService, TokenService],
})
export class UsersModule {}
