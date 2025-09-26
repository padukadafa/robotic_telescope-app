import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';



class MovementStatusCard extends StatelessWidget {

  final bool isMoving;

  final String movementStatus;class MovementStatusCard extends StatelessWidget {



  const MovementStatusCard({  final bool isMoving;

    super.key,

    required this.isMoving,  final String movementStatus;/// Movement Status Card Widget/// Movement Status Card Widget

    required this.movementStatus,

  });



  @override  const MovementStatusCard({/// /// 

  Widget build(BuildContext context) {

    return Container(    super.key,

      decoration: BoxDecoration(

        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),    required this.isMoving,/// A presentation widget that displays telescope movement status including:/// A presentation widget that displays telescope movement status including:

        borderRadius: BorderRadius.circular(16),

        border: Border.all(    required this.movementStatus,

          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),

        ),  });/// - Current movement state (moving, stationary, or calibrating)/// - Current movement state (moving, stationary, or calibrating)

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.1),

            blurRadius: 8,  @override/// - Movement progress for ongoing operations/// - Movement progress for ongoing operations

            offset: const Offset(0, 2),

          ),  Widget build(BuildContext context) {

        ],

      ),    return Container(/// - Target position information/// - Target position information

      child: Padding(

        padding: const EdgeInsets.all(20),      decoration: BoxDecoration(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),/// - Movement speed and acceleration settings/// - Movement speed and acceleration settings

          children: [

            Row(        borderRadius: BorderRadius.circular(16),

              children: [

                Container(        border: Border.all(/// /// 

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),

                    color: (isMoving ? Colors.orange : Colors.blue).withOpacity(0.2),

                    borderRadius: BorderRadius.circular(12),        ),/// This is a pure UI widget that follows clean architecture principles./// This is a pure UI widget that follows clean architecture principles.

                  ),

                  child: Icon(        boxShadow: [

                    isMoving ? Icons.directions_run : Icons.pause_circle_filled,

                    color: isMoving ? Colors.orange : Colors.blue,          BoxShadow(/// It receives movement data through parameters instead of directly/// It receives movement data through parameters instead of directly

                    size: 28,

                  ),            color: Colors.black.withOpacity(0.1),

                ),

                const SizedBox(width: 16),            blurRadius: 8,/// accessing providers, making it more testable and reusable./// accessing providers, making it more testable and reusable.

                Expanded(

                  child: Column(            offset: const Offset(0, 2),

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [          ),class MovementStatusCard extends StatelessWidget {class MovementStatusCard extends StatelessWidget {

                      Text(

                        'Movement Status',        ],

                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                          fontWeight: FontWeight.bold,      ),  /// Whether the telescope is currently moving  /// Whether the telescope is currently moving

                          color: Theme.of(context).colorScheme.onSurface,

                        ),      child: Padding(

                      ),

                      const SizedBox(height: 8),        padding: const EdgeInsets.all(20),  final bool isMoving;  final bool isMoving;

                      Text(

                        movementStatus,        child: Column(

                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),          crossAxisAlignment: CrossAxisAlignment.start,    

                        ),

                      ),          children: [

                    ],

                  ),            Row(  /// Current movement status description  /// Current movement status description

                ),

                Container(              children: [

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  decoration: BoxDecoration(                Container(  final String movementStatus;  final String movementStatus;

                    color: (isMoving ? Colors.orange : Colors.green).withOpacity(0.2),

                    borderRadius: BorderRadius.circular(20),                  padding: const EdgeInsets.all(10),

                    border: Border.all(

                      color: isMoving ? Colors.orange : Colors.green,                  decoration: BoxDecoration(    

                      width: 1,

                    ),                    color: (isMoving ? Colors.orange : Colors.blue).withOpacity(0.2),

                  ),

                  child: Text(                    borderRadius: BorderRadius.circular(12),  /// Progress of current movement (0.0 to 1.0)  /// Progress of current movement (0.0 to 1.0)

                    isMoving ? 'Moving' : 'Stationary',

                    style: TextStyle(                  ),

                      color: isMoving ? Colors.orange : Colors.green,

                      fontWeight: FontWeight.bold,                  child: Icon(  final double progress;  final double progress;

                      fontSize: 12,

                    ),                    isMoving ? Icons.directions_run : Icons.pause_circle_filled,

                  ),

                ),                    color: isMoving ? Colors.orange : Colors.blue,    

              ],

            ),                    size: 28,

          ],

        ),                  ),  /// Current movement speed as a percentage  /// Current movement speed as a percentage

      ),

    );                ),

  }

}                const SizedBox(width: 16),  final int movementSpeed;  final int movementSpeed;

                Expanded(

                  child: Column(    

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [  /// Target azimuth position (optional)  /// Target azimuth position (optional)

                      Text(

                        'Movement Status',  final double? targetAzimuth;  final double? targetAzimuth;

                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                          fontWeight: FontWeight.bold,    

                          color: Theme.of(context).colorScheme.onSurface,

                        ),  /// Target elevation position (optional)  /// Target elevation position (optional)

                      ),

                      const SizedBox(height: 8),  final double? targetElevation;  final double? targetElevation;

                      Text(

                        movementStatus,    

                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),  /// Estimated time remaining for movement (in seconds)  /// Estimated time remaining for movement (in seconds)

                        ),

                      ),  final int? estimatedTimeRemaining;  final int? estimatedTimeRemaining;

                    ],

                  ),

                ),

                Container(  const MovementStatusCard({  const MovementStatusCard({

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  decoration: BoxDecoration(    super.key,    super.key,

                    color: (isMoving ? Colors.orange : Colors.green).withOpacity(0.2),

                    borderRadius: BorderRadius.circular(20),    required this.isMoving,    required this.isMoving,

                    border: Border.all(

                      color: isMoving ? Colors.orange : Colors.green,    required this.movementStatus,    required this.movementStatus,

                      width: 1,

                    ),    required this.progress,    required this.progress,

                  ),

                  child: Text(    required this.movementSpeed,    required this.movementSpeed,

                    isMoving ? 'Moving' : 'Stationary',

                    style: TextStyle(    this.targetAzimuth,    this.targetAzimuth,

                      color: isMoving ? Colors.orange : Colors.green,

                      fontWeight: FontWeight.bold,    this.targetElevation,    this.targetElevation,

                      fontSize: 12,

                    ),    this.estimatedTimeRemaining,    this.estimatedTimeRemaining,

                  ),

                ),  });  });

              ],

            ),

          ],

        ),  @override  @override

      ),

    );  Widget build(BuildContext context) {  Widget build(BuildContext context) {

  }

}    return Container(    return Container(

      decoration: BoxDecoration(      decoration: BoxDecoration(

        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),

        borderRadius: BorderRadius.circular(16),        borderRadius: BorderRadius.circular(16),

        border: Border.all(        border: Border.all(

          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),

        ),        ),

        boxShadow: [        boxShadow: [

          BoxShadow(          BoxShadow(

            color: Colors.black.withOpacity(0.1),            color: Colors.black.withOpacity(0.1),

            blurRadius: 8,            blurRadius: 8,

            offset: const Offset(0, 2),            offset: const Offset(0, 2),

          ),          ),

        ],        ],

      ),      ),

      child: Padding(      child: Padding(

        padding: const EdgeInsets.all(20),        padding: const EdgeInsets.all(20),

        child: Column(        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,          crossAxisAlignment: CrossAxisAlignment.start,

          children: [          children: [

            Row(            Row(

              children: [              children: [

                Container(                Container(

                  padding: const EdgeInsets.all(10),                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(                  decoration: BoxDecoration(

                    color: (isMoving ? Colors.orange : Colors.blue).withOpacity(0.2),                    color: (isMoving ? Colors.orange : Colors.blue).withOpacity(0.2),

                    borderRadius: BorderRadius.circular(12),                    borderRadius: BorderRadius.circular(12),

                  ),                  ),

                  child: Icon(                  child: Icon(

                    isMoving ? Icons.directions_run : Icons.pause_circle_filled,                    isMoving ? Icons.directions_run : Icons.pause_circle_filled,

                    color: isMoving ? Colors.orange : Colors.blue,                    color: isMoving ? Colors.orange : Colors.blue,

                    size: 28,                    size: 28,

                  ),                  ),

                ),                ),

                const SizedBox(width: 16),                const SizedBox(width: 16),

                Expanded(                Expanded(

                  child: Column(                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [                    children: [

                      Text(                      Text(

                        'Movement Status',                        'Movement Status',

                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                          fontWeight: FontWeight.bold,                          fontWeight: FontWeight.bold,

                          color: Theme.of(context).colorScheme.onSurface,                          color: Theme.of(context).colorScheme.onSurface,

                        ),                        ),

                      ),                      ),

                      const SizedBox(height: 8),                      const SizedBox(height: 8),

                      Text(                      Text(

                        movementStatus,                        movementStatus,

                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),

                        ),                        ),

                      ),                      ),

                    ],                    ],

                  ),                  ),

                ),                ),

                Container(                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  decoration: BoxDecoration(                  decoration: BoxDecoration(

                    color: (isMoving ? Colors.orange : Colors.green).withOpacity(0.2),                    color: (isMoving ? Colors.orange : Colors.green).withOpacity(0.2),

                    borderRadius: BorderRadius.circular(20),                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(                    border: Border.all(

                      color: isMoving ? Colors.orange : Colors.green,                      color: isMoving ? Colors.orange : Colors.green,

                      width: 1,                      width: 1,

                    ),                    ),

                  ),                  ),

                  child: Text(                  child: Text(

                    isMoving ? 'Moving' : 'Stationary',                    isMoving ? 'Moving' : 'Stationary',

                    style: TextStyle(                    style: TextStyle(

                      color: isMoving ? Colors.orange : Colors.green,                      color: isMoving ? Colors.orange : Colors.green,

                      fontWeight: FontWeight.bold,                      fontWeight: FontWeight.bold,

                      fontSize: 12,                      fontSize: 12,

                    ),                    ),

                  ),                  ),

                ),                ),

              ],              ],

            ),            ),



            const SizedBox(height: 20),            const SizedBox(height: 20),



            // Movement Details            // Movement Details

            Column(            Column(

              children: [              children: [

                _buildDetailRow(                _buildDetailRow(

                  context,                  context,

                  'Status',                  'Status',

                  movementStatus,                  movementStatus,

                  isMoving ? Icons.play_arrow : Icons.check,                  isMoving ? Icons.play_arrow : Icons.check,

                  color: isMoving ? Colors.orange : Colors.green,                  color: isMoving ? Colors.orange : Colors.green,

                ),                ),

                if (targetAzimuth != null || targetElevation != null)                if (targetAzimuth != null || targetElevation != null)

                  _buildDetailRow(                  _buildDetailRow(

                    context,                    context,

                    'Target Position',                    'Target Position',

                    '${targetAzimuth?.toStringAsFixed(1) ?? 'N/A'}°, ${targetElevation?.toStringAsFixed(1) ?? 'N/A'}°',                    '${targetAzimuth?.toStringAsFixed(1) ?? 'N/A'}°, ${targetElevation?.toStringAsFixed(1) ?? 'N/A'}°',

                    Icons.my_location,                    Icons.my_location,

                  ),                  ),

                _buildDetailRow(                _buildDetailRow(

                  context,                  context,

                  'Movement Speed',                  'Movement Speed',

                  '$movementSpeed%',                  '$movementSpeed%',

                  Icons.speed,                  Icons.speed,

                ),                ),

                if (estimatedTimeRemaining != null)                if (estimatedTimeRemaining != null)

                  _buildDetailRow(                  _buildDetailRow(

                    context,                    context,

                    'Time Remaining',                    'Time Remaining',

                    '${estimatedTimeRemaining}s',                    '${estimatedTimeRemaining}s',

                    Icons.schedule,                    Icons.schedule,

                  ),                  ),

              ],              ],

            ),            ),



            // Progress Indicator (only show when moving)            // Progress Indicator (only show when moving)

            if (isMoving && progress > 0) ...[            if (isMoving && progress > 0) ...[

              const SizedBox(height: 16),              const SizedBox(height: 16),

              _buildProgressIndicator(context),              _buildProgressIndicator(context),

            ],            ],

          ],          ],

        ),        ),

      ),      ),

    );    );

  }  }



  /// Builds a detail row with label, value, and icon  /// Builds a detail row with label, value, and icon

  Widget _buildDetailRow(  Widget _buildDetailRow(

    BuildContext context,    BuildContext context,

    String label,    String label,

    String value,    String value,

    IconData icon, {    IconData icon, {

    Color? color,    Color? color,

  }) {  }) {

    return Padding(    return Padding(

      padding: const EdgeInsets.only(bottom: 12),      padding: const EdgeInsets.only(bottom: 12),

      child: Row(      child: Row(

        children: [        children: [

          Container(          Container(

            padding: const EdgeInsets.all(6),            padding: const EdgeInsets.all(6),

            decoration: BoxDecoration(            decoration: BoxDecoration(

              color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),              color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),

              borderRadius: BorderRadius.circular(8),              borderRadius: BorderRadius.circular(8),

            ),            ),

            child: Icon(            child: Icon(

              icon,              icon,

              size: 16,              size: 16,

              color: color ?? Theme.of(context).colorScheme.primary,              color: color ?? Theme.of(context).colorScheme.primary,

            ),            ),

          ),          ),

          const SizedBox(width: 12),          const SizedBox(width: 12),

          Expanded(          Expanded(

            child: Text(            child: Text(

              label,              label,

              style: Theme.of(context).textTheme.bodyMedium?.copyWith(              style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),

              ),              ),

            ),            ),

          ),          ),

          Text(          Text(

            value,            value,

            style: Theme.of(context).textTheme.bodyMedium?.copyWith(            style: Theme.of(context).textTheme.bodyMedium?.copyWith(

              fontWeight: FontWeight.w600,              fontWeight: FontWeight.w600,

              color: Theme.of(context).colorScheme.onSurface,              color: Theme.of(context).colorScheme.onSurface,

            ),            ),

          ),          ),

        ],        ],

      ),      ),

    );    );

  }  }



  /// Builds the progress indicator for movement tracking  /// Builds the progress indicator for movement tracking

  Widget _buildProgressIndicator(BuildContext context) {  Widget _buildProgressIndicator(BuildContext context) {

    return Column(    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,      crossAxisAlignment: CrossAxisAlignment.start,

      children: [      children: [

        Row(        Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [          children: [

            Text(            Text(

              'Progress',              'Progress',

              style: Theme.of(context).textTheme.bodyMedium?.copyWith(              style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                fontWeight: FontWeight.w600,                fontWeight: FontWeight.w600,

                color: Theme.of(context).colorScheme.onSurface,                color: Theme.of(context).colorScheme.onSurface,

              ),              ),

            ),            ),

            Text(            Text(

              '${(progress * 100).toInt()}%',              '${(progress * 100).toInt()}%',

              style: Theme.of(context).textTheme.bodySmall?.copyWith(              style: Theme.of(context).textTheme.bodySmall?.copyWith(

                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),

              ),              ),

            ),            ),

          ],          ],

        ),        ),

        const SizedBox(height: 8),        const SizedBox(height: 8),

        LinearProgressIndicator(        LinearProgressIndicator(

          value: progress,          value: progress,

          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),

          valueColor: AlwaysStoppedAnimation<Color>(          valueColor: AlwaysStoppedAnimation<Color>(

            Theme.of(context).colorScheme.primary,            Theme.of(context).colorScheme.primary,

          ),          ),

        ),        ),

      ],      ],

    );    );

  }  }

}}
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        telescopeProvider.isMoving
                            ? Icons.directions_run
                            : Icons.stop,
                        color: telescopeProvider.isMoving
                            ? Colors.orange
                            : Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Movement Status',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            telescopeProvider.isMoving
                                ? 'Telescope is moving'
                                : 'Telescope is stationary',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  'Current Action',
                  telescopeProvider.status,
                  telescopeProvider.isMoving
                      ? Icons.directions_run
                      : Icons.stop,
                ),
                _buildDetailRow(
                  context,
                  'Control Method',
                  'Stepper Motor Commands',
                  Icons.precision_manufacturing,
                ),
                if (telescopeProvider.isMoving)
                  _buildDetailRow(
                    context,
                    'Command Type',
                    'WebSocket Transmission',
                    Icons.cloud_upload,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
