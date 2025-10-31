import { Controller, Get, Logger } from '@nestjs/common';
import PodInfo from 'src/common/PodInfo';
@Controller()
export class HealthController {
  private readonly logger = new Logger(HealthController.name);

  @Get('/health')
  getHealth() {
    this.logger.log(`Health check from pod=${PodInfo.podName}`);
    return { status: 'ok', ...PodInfo };
  }

  @Get('/ready')
  getReady() {
    this.logger.log(`Ready check from pod=${PodInfo.podName}`);
    return { ready: true, ...PodInfo };
  }
  @Get('/tr')
  templateRoute() {
    return { message: 'template route' };
  }
}
