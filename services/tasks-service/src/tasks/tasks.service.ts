import { Injectable, Logger } from '@nestjs/common';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { Task, TaskDocument } from './schema/task.schema';
import { Model, Types } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(@InjectModel(Task.name) private taskModel: Model<TaskDocument>) {}

  async create(createTaskDto: CreateTaskDto): Promise<Task> {
    this.logger.log(`Creating task: ${createTaskDto.title}`);
    const { user_id, title } = createTaskDto;
    const newTask = new this.taskModel({
      user_id,
      title,
      is_done: false,
      time_created: new Date(),
    });
    try {
      this.logger.log(`Saving task for user ID: ${user_id}`);
      const savedTask = await newTask.save();
      this.logger.log(`Successfully created task with ID: ${savedTask.id}`);
      return savedTask;
    } catch (error) {
      this.logger.error(`Error creating task: ${error.message}`, error.stack);
      throw error;
    }
  }
  async getTasksByUser(userId: Types.ObjectId): Promise<Task[]> {
    return await this.taskModel.find({ user_id: userId }).exec();
  }

  findAll() {
    return `This action returns all tasks`;
  }

  findOne(id: number) {
    return `This action returns a #${id} task`;
  }

  async update(
    id: Types.ObjectId,
    updateType: { is_done?: boolean; title?: string },
  ) {
    if (updateType.is_done !== undefined) {
      return await this.taskModel.findByIdAndUpdate(
        id,
        { is_done: updateType.is_done },
        { new: true },
      );
    } else if (updateType.title !== undefined) {
      return await this.taskModel.findByIdAndUpdate(
        id,
        { title: updateType.title },
        { new: true },
      );
    }
    return `This action updates a #${id} task`;
  }

  remove(id: number) {
    return `This action removes a #${id} task`;
  }
}
