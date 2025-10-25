import {
  Injectable,
  NotFoundException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';

import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { LoginUserDto } from './dto/login-user.dto';
import { User, UserDocument } from './schemas/user.schema';

// ⬅️ Use the dedicated TokenService to avoid JwtPayload type collisions
import { TokenService } from '../auth/token.service';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private readonly tokens: TokenService,
  ) {}

  // helper to remove passwordHash before returning user
  private toSafeUser(u: UserDocument | (UserDocument & { id: string })) {
    return {
      id: u.id,
      name: u.name,
      username: u.username,
      createdAt: (u as any).createdAt,
      updatedAt: (u as any).updatedAt,
    };
  }

  // Create a new user with hashed password
  async create(createUserDto: CreateUserDto) {
    this.logger.log(`Creating user: ${createUserDto.username}`);
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const newUser = new this.userModel({
      name: createUserDto.name,
      username: createUserDto.username,
      passwordHash: hashedPassword,
    });

    const savedUser = await newUser.save();
    this.logger.log(`Successfully created user with ID: ${savedUser.id}`);
    return this.toSafeUser(savedUser);
  }

  // Login -> returns tokens + safe user
  async login(dto: LoginUserDto) {
    this.logger.log(`Login attempt for username: ${dto.username}`);

    const user = await this.userModel
      .findOne({ username: dto.username })
      .exec();
    if (!user) {
      this.logger.warn(`Login failed: username "${dto.username}" not found`);
      throw new UnauthorizedException('Invalid username or password');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      this.logger.warn(`Login failed: bad password for "${dto.username}"`);
      throw new UnauthorizedException('Invalid username or password');
    }

    // Use plain object payload (no JwtPayload conflicts)
    const payload = { sub: user.id, username: user.username };
    const accessToken = await this.tokens.signAccessToken(payload);
    const refreshToken = await this.tokens.signRefreshToken(payload);

    this.logger.log(`Login success for "${dto.username}"`);
    return {
      accessToken,
      refreshToken,
      user: this.toSafeUser(user),
    };
  }

  // Get all users (without passwordHash)
  async findAll() {
    this.logger.debug('Fetching all users from the database.');
    const users = await this.userModel.find().select('-passwordHash').exec();
    return users.map((u) => this.toSafeUser(u));
  }

  // Get a single user by ID
  async findOne(id: string) {
    this.logger.debug(`Attempting to find user by ID: ${id}`);
    const user = await this.userModel
      .findById(id)
      .select('-passwordHash')
      .exec();

    if (!user) {
      this.logger.warn(`User with ID ${id} not found.`);
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    this.logger.debug(`Found user with ID: ${id}`);
    return this.toSafeUser(user);
  }

  // Update a user (re-hash password if provided)
  async update(id: string, updateUserDto: UpdateUserDto) {
    this.logger.log(`Starting update for user ID: ${id}`);
    const updateData: any = {
      name: updateUserDto.name,
      username: updateUserDto.username,
    };

    if (updateUserDto.password) {
      this.logger.debug('Hashing new password for update.');
      updateData.passwordHash = await bcrypt.hash(updateUserDto.password, 10);
    }

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .select('-passwordHash')
      .exec();

    if (!updatedUser) {
      this.logger.warn(`Update failed: User with ID ${id} not found.`);
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    this.logger.log(`Successfully updated user ID: ${id}`);
    return this.toSafeUser(updatedUser);
  }

  // Delete a user
  async remove(id: string) {
    this.logger.warn(`Attempting to delete user ID: ${id}`);
    const result = await this.userModel.findByIdAndDelete(id).exec();

    if (!result) {
      this.logger.error(`Deletion failed: User with ID ${id} not found.`);
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    this.logger.log(`User ID: ${id} successfully deleted.`);
    return { message: `User ${id} removed successfully` };
  }
}
