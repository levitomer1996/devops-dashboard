import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Logger,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { LoginUserDto } from './dto/login-user.dto';

@Controller('users')
export class UsersController {
  private readonly logger = new Logger(UsersController.name);

  constructor(private readonly usersService: UsersService) {}

  // Create a new user
  @Post()
  async create(@Body() createUserDto: CreateUserDto) {
    this.logger.log('Attempting to create a new user.');
    const newUser = await this.usersService.create(createUserDto);
    this.logger.log(`User successfully created with ID: ${newUser.id}`);
    return newUser;
  }

  // Login
  @Post('login')
  async login(@Body() dto: LoginUserDto) {
    this.logger.log(`POST /users/login for ${dto.username}`);
    return this.usersService.login(dto);
  }

  // Get all users
  @Get()
  async findAll() {
    this.logger.log('Fetching all users.');
    return this.usersService.findAll();
  }

  // Get a single user by ID
  @Get(':id')
  async findOne(@Param('id') id: string) {
    this.logger.log(`Fetching user with ID: ${id}`);
    return this.usersService.findOne(id);
  }

  // Update a user by ID
  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    this.logger.log(`Updating user with ID: ${id}`);
    return this.usersService.update(id, updateUserDto);
  }

  // Delete a user by ID
  @Delete(':id')
  async remove(@Param('id') id: string) {
    this.logger.warn(
      `Removing user with ID: ${id}. This action is irreversible.`,
    );
    return this.usersService.remove(id);
  }
}
