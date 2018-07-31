<?php

/*
 * @copyright   2016 Mautic Contributors. All rights reserved
 * @author      Mautic
 *
 * @link        http://mautic.org
 *
 * @license     GNU/GPLv3 http://www.gnu.org/licenses/gpl-3.0.html
 */

namespace Mautic\Middleware\Dev;

use Mautic\Middleware\ConfigAwareTrait;
use Mautic\Middleware\PrioritizedMiddlewareInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\HttpKernelInterface;

class IpRestrictMiddleware implements HttpKernelInterface, PrioritizedMiddlewareInterface
{
    use ConfigAwareTrait;

    const PRIORITY = 20;

    /**
     * @var HttpKernelInterface
     */
    protected $app;

    /**
     * @var array
     */
    protected $allowedIps;

    /**
     * CatchExceptionMiddleware constructor.
     *
     * @param HttpKernelInterface $app
     */
    public function __construct(HttpKernelInterface $app)
    {
        $this->app        = $app;
        $this->allowedIps = ['127.0.0.1', 'fe80::1', '::1'];
    }

    /**
     * This check prevents access to debug front controllers
     * that are deployed by accident to production servers.
     *
     * {@inheritdoc}
     */
    public function handle(Request $request, $type = self::MASTER_REQUEST, $catch = true)
    {
        // Intentionally allow all IPs to access this for Mautibox.
        return $this->app->handle($request, $type, $catch);
    }

    /**
     * {@inheritdoc}
     */
    public function getPriority()
    {
        return self::PRIORITY;
    }
}
