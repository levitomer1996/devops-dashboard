import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get('/health')
  getHealth() {
    return { status: 'ok' };
  }

  // @Get('/tr')
  // templateRoute() {
  //   return { message: 'template route' };
  // }
  @Get('/ready')
  getReady() {
    return { ready: true };
  }
}
